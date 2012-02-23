require 'spec_helper'
require './poolboy'

describe Poolboy do
  context "with config file" do

  end

  context "without config file" do
    let(:poolboy) { Poolboy.new }
    subject { poolboy.clean }

    xit "should return an error" do
      $stderr.should_receive(:puts).with("Pools need to be defined by --pools or :pools in .zpool_status.yaml")
    end
  end
end

describe Options do
  context "without config file" do
    let(:option) { Options.new }

    subject { option.options }

    it "should not be nil" do
      should_not be_nil
    end

    it "should have the correct keys" do
      subject.should have_key(:email)
    end
  end
end
