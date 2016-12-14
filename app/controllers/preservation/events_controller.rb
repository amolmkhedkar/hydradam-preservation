# require 'preservation/events_search_builder'
# require 'preservation/event_presenter'

module Preservation
  class EventsController < ActionController::Base
    include Blacklight::Controller
    include Hydra::Controller::ControllerBehavior
    include Hydra::Catalog

    # TODO: WTF? Not adding these helpers causes `undefined variable or
    # method` errors during rendering. These missing methods are defined in
    # modules that are included within these helpers. But tracking it down was
    # a pita, because I had to first go find where the methods were being
    # defined within the Blacklight gem. Then I had to figure out why the
    # modules weren't getting included. Then I had to figure out how to
    # include them.
    helper CatalogHelper
    helper ComponentHelper
    # Override CurationConcerns::UrlHelper#url_for_document
    helper_method :url_for_document

    # Adds CurationConcerns behaviors to the application controller.
    include CurationConcerns::ApplicationControllerBehavior
    include CurationConcerns::ThemedLayoutController
    with_themed_layout '1_column'

    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception

    # Override rails path for the views by appending 'catalog' as a
    # place to look for views. This allows using default blacklight
    # views if you don't want to override each one.
    def _prefixes
      @_prefixes ||= super + ['catalog']
    end

    configure_blacklight do |config|
      config.search_builder_class = EventsSearchBuilder
      config.index.document_presenter_class = EventPresenter

      # TODO: Do not rely on dynamic suffixes here. Use Solrizer?
      config.index.title_field = :premis_event_type_tesim
      config.add_index_field :premis_event_related_object, label: "File"
      config.add_index_field :premis_event_date_time_ltsi, label: "Date", helper_method: :display_premis_event_date_time
      config.add_index_field :premis_agent_tesim, label: "Agent", helper_method: :display_premis_agent

      # Facet config
      config.add_facet_fields_to_solr_request!
      config.add_facet_field :premis_event_date_time_ltsi, label: 'Date', range: { segments: false }
      config.add_facet_field :premis_event_type_tesim, label: 'Type'
    end

    # Overrides CatalogController::UrlHelper#url_for_document. It would be
    # nice to put this method in our own Preservation::UrlHelper module but I
    # couldn't get the helper to load after CurationConcerns::UrlHelper in
    # order to overwrite the #url_for_document method. NOTE: In any event,
    # this method needs to behave roughly the same way as
    # CurationCocerns::UrlHelper#url_for_document, so if that method changes
    # change this one accordingly.
    def url_for_document(doc, _options = {})
      polymorphic_path([preservation, doc])
    end
  end
end