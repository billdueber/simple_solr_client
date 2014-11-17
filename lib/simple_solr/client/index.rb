module SimpleSolr
  class Core
    module Index
      # Add the given hash or array of hashes
      # @return self
      def add(hash_or_hashes)
        hash_or_hashes = [hash_or_hashes] if hash_or_hashes.is_a? Hash
        update(hash_or_hashes)
        self
      end

      # Send a commit
      # @return self
      def commit
        update({:commit => {}})
        self.dirty!
      end

      # Force optimization
      def optimize
        update({:optimize => {}})
        self
      end


      # A raw delete. Your query needs to be legal (e.g., escaped) already
      # @param [String] q The query to identify items to delete
      # @return self
      def delete(q)
        update({:delete => {:query => q}})
        self
      end

      # Delete all document in the index and immdiately commit
      # @return self
      def clear
        delete('*:*').commit
      end



    end
  end

end
