#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

class ArticlesIndex < Chewy::Index
  settings(
    index: {
        store: { type: :niofs }
        # In-memory indices are no longer supported.
        # https://www.elastic.co/guide/en/elasticsearch/reference/2.0/breaking_20_setting_changes.html#_in_memory_indices
    },
    analysis: {
      filter: {
        german_decompound: {
          type: 'decompound'
        },
        german_stemming: {
          type: 'stemmer',
          language: 'light_german'
        },
        german_stop: {
          type: 'stop',
          stopwords: '_german_'
        }
      },
      analyzer: {
        german_analyzer: {
          type: 'custom',
          tokenizer: 'hyphen',
          filter: %w(lowercase german_stop german_normalization german_decompound german_stemming)
        },
        german_search_analyzer: {
          type: 'custom',
          tokenizer: 'hyphen',
          filter: %w(lowercase german_stop german_normalization german_stemming)
        }
      }
    }
  )

  define_type Article.active.includes(:seller, :title_image, :categories), delete_if: ->(article) { article.sold? || article.closed? } do
    root _source: { excludes: ['content'] } do
      field :id, index: :not_analyzed
      field :title, type: 'text', analyzer: 'german_analyzer'
      #field :title_completion, value: -> { title || '' }, type: 'completion'

      field :content,  analyzer: 'german_analyzer'
      field :gtin,  index: :not_analyzed

      # filters

      field :fair, type: 'boolean'
      field :ecologic, type: 'boolean'
      field :small_and_precious, type: 'boolean'
      field :swappable, type: 'boolean'
      field :borrowable, type: 'boolean'

      # @todo consider using keywords instead of fielddata for aggregations (https://www.elastic.co/guide/en/elasticsearch/reference/5.0/fielddata.html#fielddata)
      field :condition, fielddata: true, index: :not_analyzed
      field :categories, fielddata: true, index: :not_analyzed, value: -> do
        categories.map { |c| c.self_and_ancestors.map(&:id) }.flatten
      end

      # sorting
      field :created_at, type: 'date'

      # stored attributes

      field :slug, index: :not_analyzed
      field :title_image_url_thumb, index: :not_analyzed
      field :price, value: -> { price_cents }, type: 'long'
      field :basic_price, value: -> { basic_price_cents }, type: 'long'
      field :basic_price_amount, index: :not_analyzed
      field :vat, type: 'long', index: :not_analyzed

      field :friendly_percent, type: 'long', index: :not_analyzed
      field :friendly_percent_organisation_id, index: :not_analyzed
      field :friendly_percent_organisation_nickname, index: :not_analyzed

      field :transport_pickup, type: 'boolean'
      field :transport_bike_courier, type: 'boolean'
      field :zip, value: -> do
        if self.transport_pickup || self.seller.is_a?(LegalEntity)
          self.seller.standard_address_zip
        end
      end

      # seller attributes
      field :belongs_to_legal_entity?, type: 'boolean'
      field :seller_ngo, type: 'boolean'
      # Use analyzer without decompound
      field :seller_nickname, analyzer: 'german_search_analyzer'
      field :seller_id, index: :not_analyzed
    end
  end
end
