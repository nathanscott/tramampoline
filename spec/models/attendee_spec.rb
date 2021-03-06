require 'spec_helper'

describe Attendee do
  before :each do
    ActionMailer::Base.deliveries.clear
  end
  
  describe '.create' do
    it "should automatically generate an invite code" do
      attendee = Attendee.make :invite_code => nil
      attendee.invite_code.should_not be_blank
    end
    
    it "should email the attendee" do
      attendee = Attendee.make
      
      ActionMailer::Base.deliveries.detect { |mail|
        mail.to.include?(attendee.email)
      }.should_not be_nil
    end
    
    it "should email the invited email address" do
      attendee = Attendee.make :invite_email => 'foo@bar.com'
      
      ActionMailer::Base.deliveries.detect { |mail|
        mail.to.include?('foo@bar.com')
      }.should_not be_nil
    end
    
    it "should not try to send an email if there's no invite email address" do
      Attendee.make
      
      ActionMailer::Base.deliveries.length.should == 1
    end
    
    it "should not send an invite email if there is a referral code" do
      Attendee.make(:invite_email => 'foo@bar.com', :referral_code => 'foo')
      
      ActionMailer::Base.deliveries.detect { |mail|
        mail.to.include?('foo@bar.com')
      }.should be_nil
    end
    
    it "should ensure the invite codes are unique" do
      attendee = Attendee.make
      
      Digest::SHA1.stub(:hexdigest).and_return(attendee.invite_code, 'foo')
      
      Attendee.make.invite_code.should == 'foo'
    end
  end
  
  describe '.sold_out?' do
    context 'before 29th April at 10am' do
      before :each do
        Timecop.travel Time.zone.local(2010, 4, 29, 9, 59)
      end
      
      after :each do
        Timecop.return
      end
      
      it "should return true if there are 75 registrations without referral codes" do
        75.times do
          Attendee.make
        end
        
        Attendee.should be_sold_out
      end
      
      it "should return false if there are over 75 registrations but not all with referral codes" do
        74.times do
          Attendee.make
        end
        
        Attendee.make :referral_code => 'foo'
        
        Attendee.should_not be_sold_out
      end
    end
    
    context 'after 29th April at 10am' do
      before :each do
        Timecop.travel Time.zone.local(2010, 4, 29, 10, 0)
      end
      
      after :each do
        Timecop.return
      end
      
      it "should return true if 150 places are taken" do
        150.times do
          Attendee.make
        end
        
        Attendee.should be_sold_out
      end
      
      it "should return false if 149 places are taken" do
        149.times do
          Attendee.make
        end
        
        Attendee.should_not be_sold_out
      end
    end
  end
  
  describe '#valid?' do
    {
      :name  => 'name',
      :email => 'email address'
    }.each do |attribute, human_name|
      it "should be invalid without a #{human_name}" do
        attendee = Attendee.make_unsaved attribute => nil
        attendee.should have(1).error_on(attribute)
      end
    end
  end
  
  describe '#inviting?' do
    it "should be true if there is an invite email address" do
      Attendee.make(:invite_email => 'foo@bar.com').should be_inviting
    end
    
    it "should be false if there is no invite email address" do
      Attendee.make(:invite_email => nil).should_not be_inviting
    end
  end
  
  describe '#invited?' do
    it "should be true if there is a referral code" do
      Attendee.make(:referral_code => 'foo').should be_invited
    end
    
    it "should be false if there is no referral code" do
      Attendee.make(:referral_code => nil).should_not be_invited
    end
  end
end
