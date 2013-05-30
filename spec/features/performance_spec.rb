#
# Farinopoly - Fairnopoly is an open-source online marketplace soloution.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Farinopoly.
#
# Farinopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Farinopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Farinopoly.  If not, see <http://www.gnu.org/licenses/>.
#
### This is kind of a special integration test group.
###
### Since our test suite also noitces performance issues via the bullet gem
### we need tests that specifically trigger n+1 issues.

require 'spec_helper'

include Warden::Test::Helpers

describe 'Performance' do
  include CategorySeedData

  describe "Article#index", search: true do
    before do
      3.times { FactoryGirl.create(:article, :with_fixture_image) }
      Sunspot.commit
    end
    it "should succeed" do
      visit articles_path
      page.status_code.should be 200
    end
  end

  describe "Article#new" do
    it "should succeed" do
      # Does not yet trigger n+1
      pending
      setup_categories
      visit new_article_path
      page.status_code.should be 200
    end
  end
end