require 'mina/bundler'
require 'mina/rails'

namespace :puma do
  set :web_server, :puma

  set :puma_role,      -> { fetch(:user) }
  set :puma_env,       -> { fetch(:rails_env, 'production') }
  set :puma_config,    -> { "#{fetch(:shared_path)}/config/puma.rb" }
  set :puma_socket,    -> { "#{fetch(:shared_path)}/tmp/sockets/puma.sock" }
  set :puma_state,     -> { "#{fetch(:shared_path)}/tmp/sockets/puma.state" }
  set :puma_pid,       -> { "#{fetch(:shared_path)}/tmp/pids/puma.pid" }
  set :puma_stdout,    -> { "#{fetch(:shared_path)}/log/puma.log" }
  set :puma_stderr,    -> { "#{fetch(:shared_path)}/log/puma.log" }
  set :puma_cmd,       -> { "#{fetch(:bundle_prefix)} puma" }
  set :pumactl_cmd,    -> { "#{fetch(:bundle_prefix)} pumactl" }
  set :pumactl_socket, -> { "#{fetch(:shared_path)}/tmp/sockets/pumactl.sock" }
  set :puma_root_path, -> { fetch(:current_path) }

  desc 'Start puma'
  task :start do
    puma_port_option = "-p #{fetch(:puma_port)}" if set?(:puma_port)

    comment "Starting Puma..."
    command %[
      if [ -e "#{fetch(:puma_pid)}"  ] && kill -0 "$(cat #{fetch(:puma_pid)})" 2> /dev/null; then
        echo 'Puma is already running!';
      else
        if [ -e "#{fetch(:puma_config)}" ]; then
          cd #{fetch(:puma_root_path)} && #{fetch(:puma_cmd)} -q -d -e #{fetch(:puma_env)} -C #{fetch(:puma_config)}
        else
          cd #{fetch(:puma_root_path)} && #{fetch(:puma_cmd)} -q -d -e #{fetch(:puma_env)} -b "unix://#{fetch(:puma_socket)}" #{puma_port_option} -S #{fetch(:puma_state)} --pidfile #{fetch(:puma_pid)} --control 'unix://#{fetch(:pumactl_socket)}' --redirect-stdout "#{fetch(:puma_stdout)}" --redirect-stderr "#{fetch(:puma_stderr)}"
        fi
      fi
    ]
  end

  desc 'Stop puma'
  task :stop do
    comment "Stopping Puma..."
    pumactl_command 'stop'
    command %[rm -f '#{fetch(:pumactl_socket)}']
  end

  desc 'Restart puma'
  task :restart do
    comment "Restart Puma...."
    pumactl_restart_command 'restart'
  end

  desc 'Restart puma (phased restart)'
  task :phased_restart do
    comment "Restart Puma -- phased..."
    pumactl_restart_command 'phased-restart'
  end

  desc 'Restart puma (hard restart)'
  task :hard_restart do
    comment "Restart Puma -- hard..."
    #invoke 'puma:stop'
    wait_quit_or_force_quit_command
    invoke 'puma:start'
  end

  desc 'Get status of puma'
  task :status do
    comment "Puma status..."
    pumactl_command 'status'
  end

  def pumactl_command(command)
    cmd =  %{
      if [ -e "#{fetch(:puma_pid)}"  ]; then
        if kill -0 "$(cat #{fetch(:puma_pid)})" 2> /dev/null; then
          if [ -e "#{fetch(:puma_config)}" ]; then
            cd #{fetch(:puma_root_path)} && #{fetch(:pumactl_cmd)} -F #{fetch(:puma_config)} #{command}
          else
            cd #{fetch(:puma_root_path)} && #{fetch(:pumactl_cmd)} -S #{fetch(:puma_state)} -C "unix://#{fetch(:pumactl_socket)}" --pidfile #{fetch(:puma_pid)} #{command}
          fi
        else
          rm "#{fetch(:puma_pid)}"
        fi
      else
        echo 'Puma is not running!';
      fi
    }
    command cmd
  end

  def pumactl_restart_command(command)
    puma_port_option = "-p #{fetch(:puma_port)}" if set?(:puma_port)

    cmd =  %{
      if [ -e "#{fetch(:puma_pid)}"  ] && kill -0 "$(cat #{fetch(:puma_pid)})" 2> /dev/null; then
        if [ -e "#{fetch(:puma_config)}" ]; then
          cd #{fetch(:puma_root_path)} && #{fetch(:pumactl_cmd)} -F #{fetch(:puma_config)} #{command}
        else
          cd #{fetch(:puma_root_path)} && #{fetch(:pumactl_cmd)} -S #{fetch(:puma_state)} -C "unix://#{fetch(:pumactl_socket)}" --pidfile #{fetch(:puma_pid)} #{command}
        fi
      else
        echo "Puma is not running, restarting";
        if [ -e "#{fetch(:puma_config)}" ]; then
          cd #{fetch(:puma_root_path)} && #{fetch(:puma_cmd)} -q -d -e #{fetch(:puma_env)} -C #{fetch(:puma_config)}
        else
          cd #{fetch(:puma_root_path)} && #{fetch(:puma_cmd)} -q -d -e #{fetch(:puma_env)} -b "unix://#{fetch(:puma_socket)}" #{puma_port_option} -S #{fetch(:puma_state)} --pidfile #{fetch(:puma_pid)} --control 'unix://#{fetch(:pumactl_socket)}' --redirect-stdout "#{fetch(:puma_stdout)}" --redirect-stderr "#{fetch(:puma_stderr)}"
        fi
      fi
    }
    command cmd
  end

  def wait_quit_or_force_quit_command
    cmd = %{
      quit_flag=false
      times=3
      while [ $times -gt 0 ]; do
        if [ -e "#{fetch(:puma_pid)}" ]; then
          #echo ">>> sleep 1"
          sleep 1
          times=$[$times -1]
        else
          quit_flag=true
          break
        fi
      done

      if [ $quit_flag == false ]; then
        echo "Friendly quit fail, force quit..."

        #echo "kill -9 $(cat #{fetch(:puma_pid)})"
        kill -9 $(cat "#{fetch(:puma_pid)}") 2> /dev/null

        force_quit_flag=false
        force_times=3
        while [ $force_times -gt 0 ]; do
          if [ -e "#{fetch(:puma_pid)}" ] && kill -0 $(cat "#{fetch(:puma_pid)}") 2> /dev/null; then
            sleep 1
            force_times=$[$force_times -1]
          else
            force_quit_flag=true
            echo "Force quit successfully"
            break
          fi
        done

        if [ "$force_quit_flag" == false ]; then
          echo "Force quit fail too, please check the script!!!"
          exit 1
        fi
      else
        echo "Friendly quit successfully"
      fi
    }
    command cmd
  end
end
