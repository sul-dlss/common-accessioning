# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :abbyy_watcher_systemd do
  desc 'Generate abbyy_watcher systemd service file'
  task :generate do
    on roles(:app) do
      within release_path do
        # Ensure the directory for systemd service definitions exists
        execute "mkdir -p #{release_path}/service_templates"

        # Generate the systemd service file for abbyy_watcher and upload it
        str = <<~SYSTEMD
          [Unit]
          Description=Watch for changes on ABBYY fileshare and report to SDR

          [Service]
          Type=simple
          ExecStart=smbclient #{watcher[:volume]} --authentication-file=#{watcher[:auth_file]} -c \"notify #{watcher[:watch_path]}\" | ts \"[%%Y-%%m-%%dT%%H:%%M:%%.S]\"
          Restart=always
          RestartSec=3
          StandardOutput=syslog
          StandardError=syslog
          SyslogIdentifier=%n

          [Install]
          WantedBy=multi-user.target
        SYSTEMD
        upload! StringIO.new(str), 'service_templates/abbyy_watcher.service'
      end
    end
  end

  desc 'Restart the abbyy_watcher systemd service to pick up changes'
  task :reload do
    on roles(:app) do
      within release_path do
        execute 'systemctl stop smbwatch.target'
        execute 'systemctl disable smbwatch.target'
        execute 'systemctl enable smbwatch.target'
        execute 'systemctl start smbwatch.target'
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
