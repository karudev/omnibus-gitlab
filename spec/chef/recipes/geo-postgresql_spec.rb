require 'chef_helper'

describe 'geo postgresql 9.2' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config', 'gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(GeoPgHelper).to receive(:version).and_return('9.2.18')
    allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return('9.2')

    stub_gitlab_rb(geo_postgresql: {
      enable: true
    })
  end

  it 'includes the postgresql-bin recipe' do
    expect(chef_run).to include_recipe('gitlab::postgresql-bin')
  end

  context 'with default settings' do
    it 'correctly sets the shared_preload_libraries default setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['shared_preload_libraries']).to be_nil

      expect(chef_run).to render_file('/var/opt/gitlab/geo-postgresql/data/postgresql.conf')
        .with_content(/shared_preload_libraries = ''/)
    end

    it 'correctly sets the log_line_prefix default setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['log_line_prefix']).to be_nil

      expect(chef_run).to render_file('/var/opt/gitlab/geo-postgresql/data/postgresql.conf')
        .with_content(/log_line_prefix = ''/)
    end

    it 'sets max_standby settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/max_standby_archive_delay = 30s/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/max_standby_streaming_delay = 30s/)
    end

    it 'sets archive settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/archive_mode = off/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/archive_command = ''/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/archive_timeout = 60/)
    end
  end

  context 'when user settings are set' do
    before do
      stub_gitlab_rb(geo_postgresql: {
        enable: true,
        shared_preload_libraries: 'pg_stat_statements',
        log_line_prefix: '%a',
        max_standby_archive_delay: '60s',
        max_standby_streaming_delay: '120s',
        archive_mode: 'on',
        archive_command: 'command',
        archive_timeout: '120',
        })
    end

    it 'correctly sets the shared_preload_libraries setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['shared_preload_libraries']).to eql('pg_stat_statements')

      expect(chef_run).to render_file('/var/opt/gitlab/geo-postgresql/data/postgresql.conf')
        .with_content(/shared_preload_libraries = 'pg_stat_statements'/)
    end

    it 'correctly sets the log_line_prefix setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['log_line_prefix']).to eql('%a')

      expect(chef_run).to render_file('/var/opt/gitlab/geo-postgresql/data/postgresql.conf')
        .with_content(/log_line_prefix = '%a'/)
    end

    it 'sets max_standby settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/max_standby_archive_delay = 60s/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/max_standby_streaming_delay = 120s/)
    end

    it 'sets archive settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/archive_mode = on/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/archive_command = 'command'/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/archive_timeout = 120/)
    end
  end

  context 'version specific settings' do
    it 'sets unix_socket_directory' do
      expect(chef_run.node['gitlab']['geo-postgresql']['unix_socket_directory']).to eq('/var/opt/gitlab/geo-postgresql')
      expect(chef_run.node['gitlab']['geo-postgresql']['unix_socket_directories']).to eq(nil)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content { |content|
        expect(content).to match(
          /unix_socket_directory = '\/var\/opt\/gitlab\/geo-postgresql'/
        )
        expect(content).not_to match(
          /unix_socket_directories = '\/var\/opt\/gitlab\/geo-postgresql'/
        )
      }
    end

    it 'sets checkpoint_segments' do
      expect(chef_run.node['gitlab']['geo-postgresql']['checkpoint_segments']).to eq(10)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/checkpoint_segments = 10/)
    end

    it 'does not set the max_replication_slots setting' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content { |content|
        expect(content).to_not match(/max_replication_slots = /)
      }
    end
  end
end

describe 'geo postgresql 9.6' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config', 'gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(GeoPgHelper).to receive(:version).and_return('9.6.1')
    allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return('9.6')

    stub_gitlab_rb(geo_postgresql: {
      enable: true
    })
  end

  context 'version specific settings' do
    it 'sets unix_socket_directories' do
      expect(chef_run.node['gitlab']['geo-postgresql']['unix_socket_directory']).to eq('/var/opt/gitlab/geo-postgresql')
      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content { |content|
        expect(content).to match(
          /unix_socket_directories = '\/var\/opt\/gitlab\/geo-postgresql'/
        )
        expect(content).not_to match(
          /unix_socket_directory = '\/var\/opt\/gitlab\/geo-postgresql'/
        )
      }
    end

    it 'does not set checkpoint_segments' do
      expect(chef_run).not_to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/checkpoint_segments = 10/)
    end

    it 'sets the max_replication_slots setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['max_replication_slots']).to eq(0)

      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/max_replication_slots = 0/)
    end

    it 'sets the synchronous_commit setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['synchronous_commit']).to eq('on')

      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/synchronous_commit = on/)
    end

    it 'sets the synchronous_commit setting' do
      expect(chef_run.node['gitlab']['geo-postgresql']['synchronous_standby_names']).to eq('')

      expect(chef_run).to render_file(
        '/var/opt/gitlab/geo-postgresql/data/postgresql.conf'
      ).with_content(/synchronous_standby_names = ''/)
    end
  end
end
