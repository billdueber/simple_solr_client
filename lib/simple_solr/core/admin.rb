module SimpleSolr::Core::Admin
  def ping
    get('admin/ping')
  end

  # Is the server up (and responding to a ping?)
  # @return [Boolean]
  def up?
    begin
      ping.status == 'OK'
    rescue
      false
    end
  end

  # Send a commit command
  # @return self
  def commit
    update({'commit' => {}})
    self
  end

  # Send an optimize command
  # @return self
  def optimize
    update({"optimize" => {}})
    self
  end


  # Reload this core, reading in the schema, solrconifg, etc. again
  # @return self
  def reload
    update({:commit => {}})
    schema.save
    self
  end

  # Unload the current core and delete all its files
  # @return The (non-core-specific) SimpleSolr::Client
  def unload
    @client.get('admin/cores', {:wt => 'json', :core => core, :action => 'UNLOAD', :deleteInstanceDir => true})
    @client
  end


end

