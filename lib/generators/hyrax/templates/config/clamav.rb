if defined?(Clamby)
  Clamby.configure(
    check: false,
    # daemonize: true,
    output_level: 'medium',
    fdpass: true
  )
elsif defined?(ClamAV)
  ClamAV.instance.loaddb if defined? ClamAV
end
