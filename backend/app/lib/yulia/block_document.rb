module Yulia
  # Reads the block document the editor sends.
  #
  # Strong parameters cannot express this shape: a block's props are whatever
  # its own fields declare, nested arbitrarily deep, and different for every
  # block type. Declaring `draft_content: []` permits an array of scalars and
  # quietly throws the blocks away - which is exactly what it did.
  #
  # So the document is parsed here instead, structurally: anything that is not
  # a block with an id, a type and a bag of props does not survive the trip.
  # That is a stricter guarantee than strong parameters would have given.
  module BlockDocument
    # A page is a stack of blocks, not a tree of unbounded depth. These caps
    # stop a crafted request from storing a document nothing can render.
    MAX_BLOCKS = 500
    MAX_DEPTH = 8
    MAX_STRING = 200_000

    class << self
      def sanitize(raw)
        list = unwrap(raw)
        return [] unless list.is_a?(Array)

        list.first(MAX_BLOCKS).filter_map { |entry| block(entry) }
      end

      private

        def block(entry)
          entry = unwrap(entry)
          return nil unless entry.is_a?(Hash)

          id = entry["id"].to_s
          type = entry["type"].to_s
          return nil if id.blank? || type.blank?

          # The type names a block definition, so it has to look like one. A
          # value with a slash or a dot in it is not a block, it is an attempt.
          return nil unless type.match?(/\A[a-z][a-z0-9-]*\z/)

          props = unwrap(entry["props"])
          props = {} unless props.is_a?(Hash)

          {
            "id" => id.first(64),
            "type" => type,
            "props" => value(props, 1)
          }
        end

        # Converts whatever arrived - ActionController::Parameters included -
        # into plain Ruby objects that can be written to a jsonb column.
        def value(input, depth)
          return nil if depth > MAX_DEPTH

          case unwrap(input)
          in Hash => hash
            hash.to_h { |key, nested| [ key.to_s, value(nested, depth + 1) ] }
          in Array => array
            array.first(MAX_BLOCKS).map { |nested| value(nested, depth + 1) }
          in String => string
            string.first(MAX_STRING)
          in Numeric | true | false | nil => scalar
            scalar
          else
            nil
          end
        end

        # ActionController::Parameters is not a Hash and does not respond to the
        # methods above, so it is converted first. `to_unsafe_h` is correct here
        # precisely because nothing downstream trusts the result: every value is
        # rebuilt from scratch, and the ones that end up as markup are sanitised
        # again at render time.
        def unwrap(input)
          input.respond_to?(:to_unsafe_h) ? input.to_unsafe_h : input
        end
    end
  end
end
