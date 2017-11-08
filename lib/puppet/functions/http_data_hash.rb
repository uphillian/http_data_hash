# The `http_data_hash.rb` is a hiera 5 `lookup_key` data provider function.
#
# @since 5.0.0
#
Puppet::Functions.create_function(:http_data_hash) do

  dispatch :http_data_hash do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def getData(client,url,timeout,context)
    sep=File::SEPARATOR
    uri = URI("#{url}#{client}")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER

    ssldir=Puppet.settings['ssldir']
    hostname=Puppet.settings['certname']

    # TLS/SSL Certs
    ca_file = "#{ssldir}#{sep}certs#{sep}ca.pem"
    tlscert = "#{ssldir}#{sep}certs#{sep}#{hostname}.pem"
    tlskey = "#{ssldir}#{sep}private_keys#{sep}#{hostname}.pem"

    ssl_ok=nil
    begin
      if File.exists?(ca_file) and File.exists?(tlscert) and File.exists?(tlskey)
        https.ca_file = ca_file
        https.cert = OpenSSL::X509::Certificate.new(File.read(tlscert))
        https.key = OpenSSL::PKey::RSA.new(File.read(tlskey))
        ssl_ok=true
      end
    rescue
      Puppet.debug("http_data_hash: unable to open certificate files from #{ssldir}")
      ssl_ok=false
    end
    if ssl_ok == false
      Puppet.debug('http_data_hash: problem with ssl')
      return nil
    end
    https.ssl_timeout = timeout
    https.read_timeout = timeout
    https.open_timeout = timeout

    request = Net::HTTP::Get.new(uri.path)

    # make the request
    http_result = nil

    begin
      res = https.request(request)
      Puppet.debug("http_data_hash: response #{res.body} httpok=#{res.is_a?(Net::HTTPSuccess)}")
      http_result == true
    rescue Exception => e
      Puppet.debug("http_data_hash: unable to request json from #{uri} #{e.message}")
      http_result == false
    end
    if http_result == false
      return nil
    end

    # request successful
    if res.is_a?(Net::HTTPSuccess)
      begin
        j=JSON.parse(res.body)
        return j
      rescue
        Puppet.debug("http_data_hash: Error parsing response from server")
        return nil
      end
    # request unsuccessful
    elsif res.is_a?(Net::HTTPServiceUnavailable)
      Puppet.debug("http_data_hash: Database unavailable on #{uri}")
    elsif res.is_a?(Net::HTTPNotFound)
      Puppet.debug("http_data_hash: No hieradata available for #{hostname} on #{uri}")
    else
      Puppet.debug("http_data_hash: Failed to find hieradata for #{hostname}")
    end
    return nil
  end

  def http_data_hash(options, context)
    unless options.include?('certname')
      raise ArgumentError,
        "'http_data_hash': certname must be declared in hiera.yaml when using this data_hash function"
    end

    #connect to http service
    timeout=10
    # host we are going to be looking for
    client=options['certname']

    #where to find the API
    service_url = case Puppet.settings[:server]
    when 'puppet.test'
      'https://service.test.example.com/hosts/'
    when 'puppet.dev'
      'https://service.dev.example.com/hosts/'
    else
      'https://service.example.com/hosts/'
    end

    data = getData(client,service_url,timeout,context)
    # return type of this function must be hash, it can be the data or an empty hash
    if data.class == Hash
      context.cache_all(data)
      return data
    else
      return {}
    end
  end
end
