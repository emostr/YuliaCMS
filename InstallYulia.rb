#!/usr/bin/env ruby
# frozen_string_literal: true

# InstallYulia.rb - installs and updates Yulia CMS on a Debian server.
#
# This script is the only thing a person has to run on the server, ever. It
# installs Docker, fetches Yulia, asks which domain the admin panel should live
# at, checks that the domain actually points here, writes the configuration and
# starts everything. Running it again later updates the installation instead.
#
#   sudo ruby InstallYulia.rb
#
# It is deliberately one file with no dependencies beyond Ruby's standard
# library: the machine it runs on has nothing installed yet, and asking somebody
# to install gems before they can install anything is a poor first impression.

require "fileutils"
require "io/console"
require "json"
require "net/http"
require "open3"
require "resolv"
require "securerandom"
require "uri"

module Yulia
  module Installer
    VERSION = "0.1.0"

    REPOSITORY = ENV.fetch("YULIA_REPOSITORY", "https://github.com/emostr/yulia.git")
    INSTALL_DIR = ENV.fetch("YULIA_DIR", "/opt/yulia")

    # Keys that arrive as a single control character.
    CTRL_C = "\u0003"
    CTRL_D = "\u0004"
    BACKSPACE = "\u007F"

    # --- Terminal ------------------------------------------------------------

    # Drawing and input.
    #
    # The look is deliberately old-fashioned: a framed panel on a coloured
    # field, the way installers looked when they had to work on any terminal.
    # That is not nostalgia. Somebody who has never used a terminal reads a box
    # with a title and one highlighted row far more easily than a scrolling wall
    # of command output.
    module Term
      RESET = "\e[0m"
      BOLD = "\e[1m"

      # The 16 basic colours only: they render correctly in every SSH client,
      # including the provider's browser console that people fall back to when
      # they have broken their own networking.
      BLUE_BG = "\e[44m"
      CYAN_BG = "\e[46m"
      BLACK = "\e[30m"
      RED = "\e[31m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      CYAN = "\e[36m"
      WHITE = "\e[37m"
      GREY = "\e[90m"

      # A text field reads as a field only if it looks sunken against the panel.
      GREY_FIELD = "\e[47m\e[30m"
      BRIGHT_WHITE = "\e[97m"
      BRIGHT_YELLOW = "\e[93m"
      BRIGHT_CYAN = "\e[96m"

      module_function

      def size
        rows, columns = IO.console&.winsize || [24, 80]
        # Below this the frame would collapse into noise, so the layout stops
        # shrinking and lets the terminal scroll instead.
        [[rows, 20].max, [columns, 62].max]
      end

      def clear = print("\e[2J\e[H")

      def move(row, column) = print("\e[#{row};#{column}H")

      def hide_cursor = print("\e[?25l")

      def show_cursor = print("\e[?25h")

      # Visible width. These strings carry colour codes, and counting those
      # would push every frame out of alignment.
      def width(text) = text.gsub(/\e\[[0-9;]*m/, "").length

      def pad(text, length)
        missing = length - width(text)
        missing.positive? ? text + (" " * missing) : text
      end

      def truncate(text, length)
        return text if width(text) <= length

        # The ellipsis costs three columns, so the text has to give up three.
        # Taking only one back pushed the line past the frame it sits in.
        plain = text.gsub(/\e\[[0-9;]*m/, "")
        return plain[0, [length, 0].max].to_s if length <= 3

        "#{plain[0, length - 3]}..."
      end

      # Reads one keypress, including the escape sequences arrow keys send.
      def key
        console = IO.console
        return :quit unless console

        console.raw do
          char = console.getch
          case char
          when "\e" then escape_sequence(console)
          when "\r", "\n" then :enter
          when CTRL_C, CTRL_D then :quit
          when BACKSPACE, "\b" then :backspace
          when "\t" then :tab
          when " " then :space
          else char
          end
        end
      end

      # An arrow key arrives as ESC [ A. A lone Escape means "go back", so the
      # read must not block waiting for a sequence that is not coming.
      def escape_sequence(console)
        second = console.read_nonblock(1, exception: false)
        return :escape if second.nil? || second == :wait_readable

        third = console.read_nonblock(1, exception: false)
        case third
        when "A" then :up
        when "B" then :down
        when "C" then :right
        when "D" then :left
        else :escape
        end
      end
    end

    # --- Panels --------------------------------------------------------------

    # Draws the framed screen everything else is shown inside.
    class Panel
      TITLE = "Yulia CMS"

      def initialize
        @rows, @columns = Term.size
      end

      attr_reader :rows, :columns

      # Frame geometry. The panel is centred with a margin, and never grows past
      # a comfortable reading width even on a very wide terminal.
      def box_width = [columns - 8, 92].min

      def box_left = ((columns - box_width) / 2) + 1

      def box_top = 3

      def box_height = rows - 6

      def refresh_size
        @rows, @columns = Term.size
      end

      # Paints the background field and the frame, and returns the row where
      # content may start.
      def frame(subtitle)
        Term.clear
        paint_field

        top = box_top
        left = box_left
        inner = box_width - 2

        line(top, left, "┌#{'─' * inner}┐")
        (1...box_height - 1).each do |offset|
          line(top + offset, left, "│#{' ' * inner}│")
        end
        line(top + box_height - 1, left, "└#{'─' * inner}┘")

        heading(subtitle)
        top + 3
      end

      def paint_field
        Term.move(1, 1)
        print "#{Term::BLUE_BG}#{Term::WHITE}"
        rows.times { print " " * columns }

        # Title bar and status bar, the two fixed landmarks on every screen.
        Term.move(1, 1)
        print "#{Term::CYAN_BG}#{Term::BLACK}#{Term::BOLD}"
        print Term.pad("  #{TITLE} #{VERSION}", columns)
        print Term::RESET
      end

      def status(text)
        Term.move(rows, 1)
        print "#{Term::CYAN_BG}#{Term::BLACK}"
        print Term.pad("  #{text}", columns)
        print Term::RESET
      end

      # Writes a line inside the frame, clipped to its width.
      def line(row, column, text)
        Term.move(row, column)
        print "#{Term::BLUE_BG}#{Term::BRIGHT_WHITE}#{text}#{Term::RESET}"
      end

      def write(row, text, indent: 4, colour: Term::BRIGHT_WHITE)
        available = box_width - 2 - indent
        Term.move(row, box_left + indent)
        print "#{Term::BLUE_BG}#{colour}#{Term.truncate(text, available)}#{Term::RESET}"
      end

      def heading(subtitle)
        Term.move(box_top, box_left + 3)
        print "#{Term::BLUE_BG}#{Term::BRIGHT_YELLOW}#{Term::BOLD} #{subtitle} #{Term::RESET}"
      end

      # Wraps a paragraph to the frame width, so explanatory text stays readable
      # without the caller counting characters.
      def paragraph(row, text, indent: 4, colour: Term::WHITE)
        available = box_width - 2 - indent - 2
        current = row

        text.split("\n").each do |source|
          words = source.split(" ")
          buffer = +""

          words.each do |word|
            candidate = buffer.empty? ? word : "#{buffer} #{word}"
            if candidate.length > available
              write(current, buffer, indent: indent, colour: colour)
              current += 1
              buffer = word.dup
            else
              buffer = candidate
            end
          end

          write(current, buffer, indent: indent, colour: colour)
          current += 1
        end

        current
      end
    end

    # --- Widgets -------------------------------------------------------------

    Choice = Struct.new(:key, :label, :hint, :enabled, keyword_init: true) do
      def enabled? = enabled != false
    end

    # A list the user moves through with the arrow keys.
    class Menu
      def initialize(panel, title:, intro:, choices:, footer: nil)
        @panel = panel
        @title = title
        @intro = intro
        @choices = choices
        @footer = footer
        @cursor = choices.index(&:enabled?) || 0
      end

      def run
        loop do
          draw

          case Term.key
          when :up then step(-1)
          when :down then step(1)
          when :enter, :space then return @choices[@cursor].key
          when :quit then return :quit
          when :escape then return :back
          end
        end
      end

      private

        def step(delta)
          size = @choices.size
          position = @cursor

          # Skips over anything disabled, so a greyed-out row cannot be selected
          # by pressing Enter quickly.
          size.times do
            position = (position + delta) % size
            next unless @choices[position].enabled?

            @cursor = position
            return
          end
        end

        def draw
          # A text field leaves the cursor showing. On a menu there is nothing
          # to type, and a cursor blinking beside a highlighted row reads as a
          # field the user is failing to fill in.
          Term.hide_cursor

          @panel.refresh_size
          row = @panel.frame(@title)
          row = @panel.paragraph(row, @intro) + 1

          @choices.each_with_index do |choice, index|
            selected = index == @cursor
            draw_choice(row, choice, selected)
            row += choice.hint ? 2 : 1
          end

          @panel.status(@footer || "Arrows to move  •  Enter to choose  •  Ctrl+C to quit")
          $stdout.flush
        end

        def draw_choice(row, choice, selected)
          label = " #{choice.label} "
          width = @panel.box_width - 10

          Term.move(row, @panel.box_left + 4)
          if selected
            print "#{Term::CYAN_BG}#{Term::BLACK}#{Term::BOLD}#{Term.pad(label, width)}#{Term::RESET}"
          elsif choice.enabled?
            print "#{Term::BLUE_BG}#{Term::BRIGHT_WHITE}#{Term.pad(label, width)}#{Term::RESET}"
          else
            print "#{Term::BLUE_BG}#{Term::GREY}#{Term.pad(label, width)}#{Term::RESET}"
          end

          return unless choice.hint

          @panel.write(row + 1, choice.hint, indent: 6,
                                             colour: selected ? Term::BRIGHT_CYAN : Term::GREY)
        end
    end

    # A single-line text field with validation shown as the user types.
    class Prompt
      def initialize(panel, title:, intro:, label:, initial: "", validate: nil, hint: nil)
        @panel = panel
        @title = title
        @intro = intro
        @label = label
        @buffer = initial.dup
        @validate = validate
        @hint = hint
      end

      # Returns the entered string, or nil if the user pressed Escape.
      def run
        loop do
          draw
          console = IO.console
          return @buffer unless console

          pressed = console.raw { console.getch }

          case pressed
          when "\r", "\n"
            next unless error.nil?

            return @buffer
          when CTRL_C, CTRL_D, "\e"
            return nil
          when BACKSPACE, "\b"
            @buffer = @buffer[0...-1].to_s
          else
            @buffer += pressed if pressed =~ /[[:print:]]/
          end
        end
      end

      private

        def error = @validate&.call(@buffer)

        def draw
          @panel.refresh_size
          row = @panel.frame(@title)
          row = @panel.paragraph(row, @intro) + 1

          @panel.write(row, @label, colour: Term::BRIGHT_YELLOW)
          row += 1

          field_width = @panel.box_width - 12
          Term.move(row, @panel.box_left + 4)
          print "#{Term::GREY_FIELD}#{Term.pad(" #{@buffer}", field_width)}#{Term::RESET}"
          row += 2

          message = error
          if message
            @panel.write(row, message, colour: Term::BRIGHT_YELLOW)
          elsif @hint
            @panel.write(row, @hint, colour: Term::GREY)
          end

          # The cursor sits at the end of what has been typed, so the field
          # behaves the way any other text box does.
          Term.move(row - 2, @panel.box_left + 5 + @buffer.length)
          Term.show_cursor

          @panel.status("Enter to continue  •  Esc to go back")
          $stdout.flush
        end
    end

    # --- Running commands ----------------------------------------------------

    # One step of the installation.
    Step = Struct.new(:title, :action, keyword_init: true)

    # Runs a list of steps, showing progress inside the frame and keeping the
    # last lines of output visible. A person watching an install wants to see
    # that something is happening; a person debugging a failed one wants the
    # actual error, and both are served by the same pane.
    class Runner
      TAIL = 8

      def initialize(panel, title:)
        @panel = panel
        @title = title
        @tail = []
        @done = []
      end

      def run(steps)
        steps.each_with_index do |step, index|
          @current = step.title
          @position = index + 1
          @total = steps.size
          draw

          result = step.action.call(self)

          unless result
            @failed = step.title
            draw
            return false
          end

          @done << step.title
        end

        @current = nil
        draw
        true
      end

      # Records a line of progress. Long output is kept to a tail so the frame
      # does not scroll away.
      def say(text)
        text.to_s.split("\n").each do |line|
          next if line.strip.empty?

          @tail << line.rstrip
        end
        @tail = @tail.last(TAIL)
        draw
      end

      # Runs a shell command, streaming its output into the pane.
      def sh(*command, env: {})
        say("$ #{command.join(' ')}")

        ok = false
        Open3.popen2e(env, *command) do |stdin, output, thread|
          stdin.close
          output.each_line { |line| say(line) }
          ok = thread.value.success?
        end
        ok
      rescue Errno::ENOENT => e
        say("not found: #{e.message}")
        false
      end

      def draw
        @panel.refresh_size
        row = @panel.frame(@title)

        if @failed
          @panel.write(row, "Step failed: #{@failed}", colour: Term::BRIGHT_YELLOW)
        elsif @current
          @panel.write(row, "[#{@position}/#{@total}] #{@current}", colour: Term::BRIGHT_YELLOW)
        else
          @panel.write(row, "Finished.", colour: Term::GREEN)
        end
        row += 2

        @done.last(4).each do |title|
          @panel.write(row, "OK  #{title}", colour: Term::GREEN)
          row += 1
        end
        row += 1

        @tail.each do |line|
          @panel.write(row, line, indent: 4, colour: Term::GREY)
          row += 1
        end

        @panel.status(@failed ? "Press any key" : "Working...")
        $stdout.flush
      end
    end

    # --- The system this runs on ---------------------------------------------

    # Everything the installer needs to know or change about the machine.
    module System
      module_function

      def root? = Process.uid.zero?

      def debian?
        File.exist?("/etc/debian_version")
      end

      def release
        return "unknown" unless File.exist?("/etc/os-release")

        File.read("/etc/os-release")[/^PRETTY_NAME="?([^"\n]+)"?/, 1] || "unknown"
      end

      def memory_mb
        line = File.read("/proc/meminfo")[/^MemTotal:\s+(\d+) kB/, 1]
        line ? line.to_i / 1024 : 0
      rescue Errno::ENOENT
        0
      end

      def disk_free_gb(path = "/")
        output = `df -BG #{path} 2>/dev/null`.lines[1]
        output ? output.split[3].to_i : 0
      end

      def command?(name)
        system("command -v #{name} > /dev/null 2>&1")
      end

      def docker_running?
        system("docker info > /dev/null 2>&1")
      end

      # This machine's address as the outside world sees it, which is what a
      # domain's A record has to match.
      def public_ip
        @public_ip ||= begin
          uri = URI("https://api.ipify.org")
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                     open_timeout: 5, read_timeout: 5) { |http| http.get(uri.path) }
          response.body.to_s.strip
        rescue StandardError
          nil
        end
      end

      def resolve(host)
        Resolv::DNS.open do |dns|
          dns.timeouts = 5
          v4 = dns.getresources(host, Resolv::DNS::Resource::IN::A).map { |r| r.address.to_s }
          v6 = dns.getresources(host, Resolv::DNS::Resource::IN::AAAA).map { |r| r.address.to_s }
          v4 + v6
        end
      rescue StandardError
        []
      end

      def installed? = File.exist?(File.join(INSTALL_DIR, "docker-compose.yml"))

      def env_file = File.join(INSTALL_DIR, ".env")

      def read_env
        return {} unless File.exist?(env_file)

        File.readlines(env_file).each_with_object({}) do |line, values|
          next if line.start_with?("#") || !line.include?("=")

          key, value = line.chomp.split("=", 2)
          values[key] = value
        end
      end
    end

    # --- Screens -------------------------------------------------------------

    # The installer itself: the sequence of screens and what each one does.
    class Application
      def initialize
        @panel = Panel.new
        @settings = System.read_env
      end

      def run
        Term.hide_cursor
        welcome_loop
      ensure
        Term.show_cursor
        Term.clear
        Term.move(1, 1)
      end

      private

        def welcome_loop
          loop do
            case welcome
            when :install then install
            when :update then update
            when :status then status_screen
            when :logs then logs_screen
            when :stop then stop_screen
            when :quit, :back then return
            end
          end
        end

        def welcome
          installed = System.installed?

          intro =
            if installed
              "Yulia is already installed in #{INSTALL_DIR}.\n\n" \
              "Updating fetches the newest version, rebuilds the containers and applies any " \
              "database changes. Your sites, pages and files are left alone."
            else
              "This will install Yulia on this server: Docker, the application itself, and a web " \
              "server that obtains HTTPS certificates on its own.\n\n" \
              "You will be asked for the domain the admin panel should live at. Everything else " \
              "is decided for you."
            end

          choices =
            if installed
              [
                Choice.new(key: :update, label: "Update Yulia",
                           hint: "Fetch the newest version and restart"),
                Choice.new(key: :status, label: "Status",
                           hint: "What is running, and where the panel is"),
                Choice.new(key: :logs, label: "Recent log", hint: "The last lines from the app"),
                Choice.new(key: :stop, label: "Stop Yulia", hint: "Sites go offline until started again"),
                Choice.new(key: :quit, label: "Exit")
              ]
            else
              [
                Choice.new(key: :install, label: "Install Yulia",
                           hint: "About five minutes, mostly waiting for downloads"),
                Choice.new(key: :quit, label: "Exit")
              ]
            end

          Menu.new(@panel, title: installed ? "Installed" : "Welcome",
                          intro: intro, choices: choices).run
        end

        # --- Installing ------------------------------------------------------

        def install
          return unless preflight

          domain = ask_domain
          return if domain.nil?

          email = ask_email(domain)
          return if email.nil?

          return unless confirm(domain, email)

          runner = Runner.new(@panel, title: "Installing")
          ok = runner.run(install_steps(domain, email))

          ok ? finished(domain) : failed
        end

        def preflight
          problems = []
          problems << "This script must be run with sudo." unless System.root?
          unless System.debian?
            problems << "This does not look like Debian. The guide assumes a fresh Debian server."
          end
          if System.memory_mb.positive? && System.memory_mb < 1500
            problems << "Only #{System.memory_mb} MB of memory. Yulia wants at least 2 GB."
          end
          if System.disk_free_gb < 5
            problems << "Only #{System.disk_free_gb} GB free. Yulia wants at least 10 GB."
          end

          return true if problems.empty?

          choice = Menu.new(
            @panel,
            title: "Before we start",
            intro: "#{problems.join("\n\n")}\n\nYou can continue anyway, but the installation may " \
                   "fail part way through.",
            choices: [
              Choice.new(key: :back, label: "Go back"),
              Choice.new(key: :anyway, label: "Continue anyway")
            ]
          ).run

          choice == :anyway
        end

        def ask_domain
          Prompt.new(
            @panel,
            title: "Domain for the admin panel",
            intro: "Which domain will you use to reach the admin panel? A subdomain is the usual " \
                   "choice, for example admin.example.com.\n\n" \
                   "Before continuing, point it at this server with an A record:\n" \
                   "    #{System.public_ip || 'this server\'s IP address'}",
            label: "Domain",
            initial: @settings["ADMIN_DOMAIN"].to_s,
            hint: "Only the name: no https://, no trailing slash",
            validate: lambda { |value|
              return "Type the domain to continue." if value.strip.empty?
              return "Leave out the https:// - only the name." if value.include?("/")

              unless value.match?(/\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/i)
                return "That does not look like a domain name."
              end

              nil
            }
          ).run&.strip&.downcase
        end

        def ask_email(domain)
          loop do
            email = Prompt.new(
              @panel,
              title: "Address for certificates",
              intro: "Let's Encrypt issues the HTTPS certificate for #{domain} free of charge, and " \
                     "writes to this address if a certificate is ever about to expire.\n\n" \
                     "It is not shown anywhere on your sites.",
              label: "Email",
              initial: @settings["ACME_EMAIL"].to_s,
              validate: lambda { |value|
                return "Type an address to continue." if value.strip.empty?
                return "That does not look like an address." unless value.include?("@")

                nil
              }
            ).run

            return nil if email.nil?

            return email.strip unless check_dns(domain) == :retry
          end
        end

        # The single most common way a self-hosted site fails is a DNS record
        # that is missing or still pointing at the previous host. Checking it
        # here turns a browser security warning into a sentence with a fix in it.
        def check_dns(domain)
          addresses = System.resolve(domain)
          expected = System.public_ip

          return :ok if expected && addresses.include?(expected)

          intro =
            if addresses.empty?
              "#{domain} has no DNS record yet.\n\n" \
              "Add an A record for it at your registrar, pointing to #{expected || 'this server'}. " \
              "Changes can take anywhere from a minute to a few hours to spread."
            elsif expected.nil?
              "Could not work out this server's public address, so there is nothing to compare " \
              "against. #{domain} currently resolves to #{addresses.join(', ')}.\n\n" \
              "If that is this server, carry on."
            else
              "#{domain} points at #{addresses.join(', ')}, but this server is #{expected}.\n\n" \
              "Until the record points here, Let's Encrypt cannot issue a certificate and the " \
              "browser will show a security warning."
            end

          Menu.new(
            @panel,
            title: "Checking the domain",
            intro: intro,
            choices: [
              Choice.new(key: :retry, label: "Check again", hint: "After changing the DNS record"),
              Choice.new(key: :ignore, label: "Continue anyway",
                         hint: "Certificates will fail until DNS is right")
            ]
          ).run
        end

        def confirm(domain, email)
          Menu.new(
            @panel,
            title: "Ready to install",
            intro: "Admin panel:  https://#{domain}\n" \
                   "Certificates: #{email}\n" \
                   "Directory:    #{INSTALL_DIR}\n\n" \
                   "This installs Docker, downloads Yulia and starts it. Nothing already on this " \
                   "server is removed.",
            choices: [
              Choice.new(key: :go, label: "Install"),
              Choice.new(key: :back, label: "Go back")
            ]
          ).run == :go
        end

        def install_steps(domain, email)
          [
            Step.new(title: "Updating the package list",
                     action: ->(r) { r.sh("apt-get", "update", "-qq") }),

            Step.new(title: "Installing basic packages",
                     action: lambda { |r|
                       r.sh("apt-get", "install", "-y", "--no-install-recommends",
                            "ca-certificates", "curl", "git", "gnupg",
                            env: { "DEBIAN_FRONTEND" => "noninteractive" })
                     }),

            Step.new(title: "Installing Docker", action: method(:install_docker)),

            Step.new(title: "Fetching Yulia", action: method(:fetch_repository)),

            Step.new(title: "Writing the configuration",
                     action: ->(r) { write_env(r, domain, email) }),

            Step.new(title: "Building the application",
                     action: ->(r) { compose(r, "build") }),

            Step.new(title: "Starting everything",
                     action: ->(r) { compose(r, "up", "-d") }),

            Step.new(title: "Waiting for the first response", action: method(:wait_for_health))
          ]
        end

        def install_docker(runner)
          if System.command?("docker") && System.docker_running?
            runner.say("Docker is already installed.")
            return true
          end

          # Docker's own convenience script, which is what Docker's installation
          # guide recommends. Fetched to a file first so that a truncated
          # download cannot be executed halfway.
          script = "/tmp/get-docker.sh"
          return false unless runner.sh("curl", "-fsSL", "https://get.docker.com", "-o", script)

          ok = runner.sh("sh", script)
          FileUtils.rm_f(script)
          return false unless ok

          runner.sh("systemctl", "enable", "--now", "docker")
        end

        def fetch_repository(runner)
          if Dir.exist?(File.join(INSTALL_DIR, ".git"))
            runner.say("Already downloaded; fetching the newest version.")
            return runner.sh("git", "-C", INSTALL_DIR, "fetch", "--depth", "1", "origin", "main") &&
                   runner.sh("git", "-C", INSTALL_DIR, "reset", "--hard", "origin/main")
          end

          FileUtils.mkdir_p(File.dirname(INSTALL_DIR))
          runner.sh("git", "clone", "--depth", "1", REPOSITORY, INSTALL_DIR)
        end

        # Written only once. A second run must not replace the database password
        # or the secret key, because that would lock the installation out of its
        # own data.
        def write_env(runner, domain, email)
          existing = System.read_env
          path = System.env_file

          values = {
            "ADMIN_DOMAIN" => domain,
            "ACME_EMAIL" => email,
            "CADDYFILE" => "./caddy/Caddyfile",
            "HTTP_BIND" => "0.0.0.0",
            "HTTP_PORT" => "80",
            "HTTPS_PORT" => "443",
            "POSTGRES_USER" => existing["POSTGRES_USER"] || "yulia",
            "POSTGRES_PASSWORD" => existing["POSTGRES_PASSWORD"] || SecureRandom.hex(24),
            "POSTGRES_DB" => existing["POSTGRES_DB"] || "yulia_production",
            # Not published on a server: the database is reachable only from the
            # other containers.
            "POSTGRES_BIND" => "127.0.0.1",
            "POSTGRES_PORT" => "5433",
            "SECRET_KEY_BASE" => existing["SECRET_KEY_BASE"] || SecureRandom.hex(64),
            "SESSION_DAYS" => existing["SESSION_DAYS"] || "30",
            "MAX_UPLOAD_MB" => existing["MAX_UPLOAD_MB"] || "64"
          }

          body = +"# Written by InstallYulia.rb. Keep this file: it holds the keys to your data.\n"
          values.each { |key, value| body << "#{key}=#{value}\n" }

          File.write(path, body)
          FileUtils.chmod(0o600, path)
          runner.say("Wrote #{path}")
          @settings = values
          true
        end

        def compose(runner, *arguments)
          runner.sh("docker", "compose", "-f", File.join(INSTALL_DIR, "docker-compose.yml"),
                    "--project-directory", INSTALL_DIR, *arguments)
        end

        # The containers report healthy before the application has finished its
        # first boot, so this polls the health endpoint rather than trusting the
        # exit status of "up".
        def wait_for_health(runner)
          60.times do |attempt|
            output, = Open3.capture2e(
              "docker", "compose", "-f", File.join(INSTALL_DIR, "docker-compose.yml"),
              "--project-directory", INSTALL_DIR,
              "exec", "-T", "app", "curl", "-fsS", "http://127.0.0.1:3000/up"
            )

            return true if output.include?("green") || output.include?("<html")

            runner.say("waiting for the application... (#{attempt + 1})") if (attempt % 5).zero?
            sleep 2
          end

          runner.say("The application did not answer in time. Check the log from the main menu.")
          false
        end

        def finished(domain)
          Menu.new(
            @panel,
            title: "Done",
            intro: "Yulia is running.\n\n" \
                   "Open https://#{domain} in your browser. It will ask you to create the owner " \
                   "account and to set up a second factor, and then you are in the admin panel.\n\n" \
                   "You do not need to come back to this server. Updates are done by running this " \
                   "script again and choosing Update.",
            choices: [Choice.new(key: :back, label: "Back to the menu")]
          ).run
        end

        def failed
          Menu.new(
            @panel,
            title: "Did not finish",
            intro: "Something went wrong. The output above says where.\n\n" \
                   "Running this script again is safe: it picks up where it left off rather than " \
                   "starting over.",
            choices: [Choice.new(key: :back, label: "Back to the menu")]
          ).run
        end

        # --- Updating --------------------------------------------------------

        def update
          runner = Runner.new(@panel, title: "Updating")

          ok = runner.run([
            Step.new(title: "Fetching the newest version", action: method(:fetch_repository)),
            Step.new(title: "Rebuilding", action: ->(r) { compose(r, "build") }),
            # The entrypoint runs migrations on the way up, so restarting is all
            # that is needed to apply database changes.
            Step.new(title: "Restarting", action: ->(r) { compose(r, "up", "-d") }),
            Step.new(title: "Waiting for the first response", action: method(:wait_for_health))
          ])

          domain = System.read_env["ADMIN_DOMAIN"].to_s

          Menu.new(
            @panel,
            title: ok ? "Updated" : "Did not finish",
            intro: ok ? "Yulia is up to date and running at https://#{domain}." \
                      : "The update did not finish. The output above says where it stopped. " \
                        "Your data has not been touched.",
            choices: [Choice.new(key: :back, label: "Back to the menu")]
          ).run
        end

        # --- Status and logs -------------------------------------------------

        def status_screen
          output, = Open3.capture2e(
            "docker", "compose", "-f", File.join(INSTALL_DIR, "docker-compose.yml"),
            "--project-directory", INSTALL_DIR, "ps", "--format",
            "{{.Service}} {{.Status}}"
          )

          settings = System.read_env
          lines = output.lines.map(&:chomp).reject(&:empty?)

          intro = +"Admin panel: https://#{settings['ADMIN_DOMAIN']}\n"
          intro << "Directory:   #{INSTALL_DIR}\n\n"
          intro << (lines.empty? ? "Nothing is running." : lines.join("\n"))

          Menu.new(@panel, title: "Status", intro: intro,
                          choices: [Choice.new(key: :back, label: "Back")]).run
        end

        def logs_screen
          output, = Open3.capture2e(
            "docker", "compose", "-f", File.join(INSTALL_DIR, "docker-compose.yml"),
            "--project-directory", INSTALL_DIR, "logs", "--tail", "14", "app"
          )

          Menu.new(@panel, title: "Recent log",
                          intro: output.lines.last(14).join.strip,
                          choices: [Choice.new(key: :back, label: "Back")]).run
        end

        def stop_screen
          confirmed = Menu.new(
            @panel,
            title: "Stop Yulia",
            intro: "Every site on this server goes offline until Yulia is started again. " \
                   "Nothing is deleted.",
            choices: [
              Choice.new(key: :back, label: "Go back"),
              Choice.new(key: :stop, label: "Stop")
            ]
          ).run

          return unless confirmed == :stop

          runner = Runner.new(@panel, title: "Stopping")
          runner.run([Step.new(title: "Stopping the containers",
                               action: ->(r) { compose(r, "down") })])

          Menu.new(@panel, title: "Stopped",
                          intro: "Yulia is stopped. Run this script again to start it.",
                          choices: [Choice.new(key: :back, label: "Back")]).run
        end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    Yulia::Installer::Application.new.run
  rescue Interrupt
    Yulia::Installer::Term.show_cursor
    Yulia::Installer::Term.clear
    puts "Cancelled. Nothing was left half-done: run the script again when you are ready."
    exit 130
  end
end
