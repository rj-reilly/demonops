#
# Cookbook Name:: demonops
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'demonops::default' do
  include ChefVault::TestFixtures.rspec_shared_context
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(log_level: :error) do |node, server|
         server.create_data_bag('demonops', {
          'dev0' => parse_data_bag('demonops/dev0.json')
        })
      end.converge(described_recipe)
    end


      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
    end
  end
