# frozen_string_literal: true
ClamAV.instance.loaddb if defined? ClamAV

Clamby.configure({ daemonize: true, fdpass: true }) if defined? Clamby
