require "test_helper"
require "shrine/plugins/restore_cached_data"

describe Shrine::Plugins::RestoreCachedData do
  before do
    @attacher = attacher { plugin :restore_cached_data }
    @shrine   = @attacher.shrine_class
  end

  describe "Attacher" do
    describe "#assign" do
      it "doesn't reextract metadata of current cached file" do
        file = @attacher.attach_cached(fakeio, metadata: false)

        @shrine.any_instance.expects(:extract_metadata).never

        @attacher.assign({ id: file.id, storage: file.storage_key })
      end

      it "doesn't reextract metadata of current stored file" do
        file = @attacher.attach(fakeio, metadata: false)

        @shrine.any_instance.expects(:extract_metadata).never

        @attacher.assign({ id: file.id, storage: file.storage_key })
      end
    end

    describe "#attach_cached" do
      it "reextracts metadata of set cached files" do
        cached_file = @attacher.upload(fakeio("a" * 1024), :cache)
        cached_file.metadata["size"] = 5

        @attacher.attach_cached(cached_file.data)

        assert_equal 1024, @attacher.file.metadata["size"]
      end

      it "skips extracting if the file is not cached" do
        stored_file = @attacher.upload(fakeio, :store)

        @shrine.any_instance.expects(:extract_metadata).never

        assert_raises(Shrine::Error) do
          @attacher.attach_cached(stored_file.data)
        end
      end

      it "forwards options to uploader" do
        cached_file = @attacher.upload(fakeio, :cache)

        @shrine.plugin :add_metadata
        metadata_options = nil
        @shrine.add_metadata(:foo) { |io, options| metadata_options = options }

        @attacher.attach_cached(cached_file.data, foo: "bar")

        assert_equal "bar", metadata_options[:foo]
      end

      it "fowards attacher context to uploader" do
        @shrine.plugin :add_metadata
        metadata_options = nil
        @shrine.add_metadata(:foo) { |io, options| metadata_options = options }

        cached_file = @attacher.upload(fakeio, :cache)
        @attacher.context.merge!(foo: "bar")
        @attacher.attach_cached(cached_file.data)

        assert_equal "bar", metadata_options[:foo]
      end

      it "works with versions plugin" do
        @shrine.plugin :versions
        cached_file = @attacher.upload(fakeio("a" * 1024), :cache)
        cached_file.metadata["size"] = 5

        @attacher.attach_cached({ "version" => cached_file.data })

        assert_equal 1024, @attacher.file[:version].metadata["size"]
      end
    end
  end
end
