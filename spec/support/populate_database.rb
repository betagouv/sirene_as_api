require 'rails_helper'

def populate_database_before_test
  before :each do
    populate_test_database
  end
end

def populate_test_database
  5.times do
    create(:etablissement)
  end
end

def populate_test_database_with_only_diffusion
  5.times do
    create(:etablissement, nature_mise_a_jour: %w[I F C D].cycle)
  end
end

def populate_test_database_with_no_diffusion
  2.times do
    create(:etablissement, nature_mise_a_jour: %w[O E].cycle)
  end
end

def populate_test_database_with_all
  10.times do
    create(:etablissement, nature_mise_a_jour: %w[I F C D E O].cycle)
  end
end
