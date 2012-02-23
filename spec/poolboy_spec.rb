require 'spec_helper'
require './poolboy'

describe Poolboy do

  context "without config file" do
    before do
      File.stub(:exists?).and_return(false)
      poolboy.should_receive(:print_error).with("Pools need to be defined by --pools or :pools in .zpool_status.yaml")
    end
    let(:poolboy) { Poolboy.new }
    subject { poolboy.clean }

    it "should return an error" do
      should be_nil
    end
  end

  context "with valid Options" do
    before do
      File.stub(:exists?).and_return(false)
      ARGV = %w"-p tank Girl -e test@email.com -a test.com --email-password test123 -s"
    end
  end
end

describe Options do
  context "without config file or arguments" do
    before do
      File.stub(:exists?).and_return(false)
    end
    let(:option) { Options.new }

    subject { option.options }

    it "should not be nil" do
      should_not be_nil
    end

    it "should have the correct keys" do
      subject.should have_key(:email)
      subject.should have_key(:email_password)
      subject.should have_key(:email_server)
      subject.should have_key(:send_email)
      subject.should have_key(:pools)
    end

    it "should have nil or false values" do
      subject[:email].should be_nil
      subject[:email_password].should be_nil
      subject[:email_server].should be_nil
      subject[:send_email].should be_false
      subject[:pools].should be_nil
    end
  end

  context "with arguments" do
    before do
      File.stub(:exists?).and_return(false)
      ARGV = %w"-p Tank Girl -e test@email.com -a test.com --email-password test123 -s"
    end

    let(:option) { Options.new }
    subject { option.options }

    it "should have the correct values" do
      subject[:email].should == "test@email.com"
      subject[:email_password].should == "test123"
      subject[:email_server].should == "test.com"
      subject[:send_email].should == true
      subject[:pools].should == ["Tank", "Girl"]
    end
  end

  context "with file" do
    before do
      YAML.stub(:load_file).and_return(email: "test@email.com",
                                       email_password: "test123",
                                       email_server: "test.com",
                                       send_email: true,
                                       pools: ["Tank", "Girl"])
    end

    let(:option) { Options.new}
    subject { option.options }

    it "should have the correct values" do
      subject[:email].should == "test@email.com"
      subject[:email_password].should == "test123"
      subject[:email_server].should == "test.com"
      subject[:send_email].should == true
      subject[:pools].should == ["Tank", "Girl"]
    end
  end
end
