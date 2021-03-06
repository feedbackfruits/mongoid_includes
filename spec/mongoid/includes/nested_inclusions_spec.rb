require 'spec_helper'

describe Mongoid::Includes::Criteria do

  describe '#includes' do

    context 'inclusion has additional options' do
      Given(:band) { Band.create!(name: 'Pink Floyd') }
      Given {
        Album.create!(name: 'Wish You Were Here', release: Date.new(1975), owner: band)
        Album.create!(name: 'The Dark Side of the Moon', release: Date.new(1973), owner: band)
      }
      Given(:criteria) {
        Band.includes(:albums, with: ->(albums) { albums.lt(release: Date.new(1974)) })
      }
      When(:result) { criteria.entries.first }
      Then { expect(result).to eq band }
      And  { result.albums.first.name == 'The Dark Side of the Moon' }
      And  { result.albums.size == 1 }
      And  { band.albums.size == 2 }
    end
  end

  describe '#inclusions' do
    Given(:inclusions) { criteria.inclusions }

    context 'does not duplicate inclusions' do
      When(:criteria) {
        Band.includes(:songs, :owner, from: :albums)
          .includes(:musicians, :albums)
          .includes(:songs, :owner, from: :albums)
      }
      Then { inclusions.size == 4 }
    end

    context 'each inclusion has valid properties' do
      Given(:metadata) { Band.relations['albums'] }
      Given(:nested_metadata) { Album.relations['songs'] }
      Given(:polymorphic_metadata) { Album.relations['owner'] }

      When(:criteria) { Band.includes(:songs, :owner, from: :albums) }

      Then { inclusions.size == 3 }
      And  { expect(inclusions).to include(metadata) }
      And  { expect(inclusions).to include(nested_metadata) }
      And  { expect(inclusions).to include(polymorphic_metadata) }
      And  { !inclusions.to_a[0].nested? && !inclusions.to_a[0].polymorphic_belongs_to? }
      And  { inclusions.to_a[1].nested? && !inclusions.to_a[1].polymorphic_belongs_to? }
      And  { inclusions.to_a[2].nested? && inclusions.to_a[2].polymorphic_belongs_to? }
    end

    context 'works with self-referencing relations' do
      Given(:metadata) { Node.relations['children'] }

      When(:criteria) {
        Node.includes(:children, from: :children)
      }

      Then { inclusions.size == 2 }
      And  { expect(inclusions.to_a[0].metadata).to eq(metadata) }
      And  { expect(inclusions.to_a[0].from).to be_nil }
      And  { expect(inclusions.to_a[1].metadata).to eq(metadata) }
      And  { expect(inclusions.to_a[1].from).to eq(:children) }
    end
  end
end
