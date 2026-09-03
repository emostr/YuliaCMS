require "open3"
require "tmpdir"

# Compiles a user-written Svelte block into a bundle the public site can load.
#
# This runs on the server, not on a developer's machine, because the promise
# Yulia makes is that you never go back to the server after installing it. The
# cost is Node inside the runtime image; the benefit is that writing a block in
# the admin panel is enough to have it live.
class CompileIslandJob < ApplicationJob
  queue_as :default

  # A compile that has not finished by now is stuck, and holding the queue open
  # for it helps nobody.
  TIMEOUT = 90

  BUILDER = Rails.root.join("../frontend/scripts/build-island.mjs").expand_path

  def perform(block_type_id)
    block_type = BlockType.find_by(id: block_type_id)
    return unless block_type&.svelte?

    block_type.update!(build_status: "building", build_log: "")

    Dir.mktmpdir("yulia-island") do |dir|
      source = File.join(dir, "#{block_type.key}.svelte")
      File.write(source, block_type.source)

      output_dir = islands_dir(block_type.site)
      FileUtils.mkdir_p(output_dir)

      result = run_builder(source: source, output_dir: output_dir, key: block_type.key)

      if result[:success]
        block_type.update!(
          build_status: "ready",
          build_log: result[:log],
          asset_path: "/yulia/islands/#{block_type.site_id}/#{block_type.key}.js"
        )
      else
        # The log is shown verbatim in the admin panel: a compiler error the
        # author can read is worth more than a tidy "build failed".
        block_type.update!(build_status: "failed", build_log: result[:log])
      end
    end
  end

  private

    # Islands are written under the storage volume so they survive an image
    # rebuild, and are served from there as static files.
    def islands_dir(site)
      Rails.root.join("storage/islands", site.id.to_s)
    end

    def run_builder(source:, output_dir:, key:)
      unless BUILDER.exist?
        return { success: false, log: "the island builder is missing at #{BUILDER}" }
      end

      stdout, stderr, status = Open3.capture3(
        "node", BUILDER.to_s,
        "--input", source,
        "--outdir", output_dir.to_s,
        "--name", key,
        chdir: BUILDER.dirname.parent.to_s
      )

      { success: status.success?, log: [ stdout, stderr ].reject(&:blank?).join("\n").strip }
    rescue Errno::ENOENT
      { success: false, log: "node is not available in this container, so Svelte blocks cannot be compiled" }
    end
end
