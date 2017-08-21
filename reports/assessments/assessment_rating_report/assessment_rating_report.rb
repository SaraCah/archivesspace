class AssessmentRatingReport < AbstractReport

  # Gives us each_slice, used below
  include Enumerable

  attr_reader :values_of_interest

  register_report({
                    :params => [["from", Date, "The start of report range"],
                                ["to", Date, "The start of report range"],
                                ["rating", "Rating", "The assessment rating to report on"],
                                ["values", "RatingValues", "The assessment rating values to include"]]
                  })

  def initialize(params, job, db)
    super

    @rating_id = Integer(params.fetch('rating'))
    @values_of_interest = params.keys.map {|key|
      if key =~ /\Avalue_[0-9]+\z/ && params[key] == 'on'
        # Don't really need integers but it's a decent sanitization step.
        Integer(key.split(/_/)[1])
      else
        nil
      end
    }.compact

    if @rating_id.nil? || @values_of_interest.empty?
      raise "Need a rating and at least one value of interest"
    end

    from = params["from"].to_s.empty? ? Time.at(0).to_s : params["from"]
    to = params["to"].to_s.empty? ? Time.now.to_s : params["to"]

    @from = DateTime.parse(from).to_time.strftime("%Y-%m-%d %H:%M:%S")
    @to = DateTime.parse(to).to_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def template
    'assessment_rating_report.erb'
  end

  def rating_name
    db[:assessment_attribute_definition].filter(:id => @rating_id).get(:label)
  end

  def query
    base_query = db[:assessment]
                   .join(:assessment_attribute, :assessment_id => :assessment__id)
                   .join(:assessment_rlshp, :assessment_id => :assessment_id)
                   .join(:assessment_attribute_definition, :id => :assessment_attribute__assessment_attribute_definition_id)
                   .filter(:assessment_attribute_definition__id => @rating_id)
                   .filter(:assessment_attribute__value => @values_of_interest.map(&:to_s))
                   .filter(:assessment__survey_begin => (@from..@to))


    base_selection = [
      Sequel.as(:assessment_attribute__value, :rating),
      Sequel.as(:assessment__id, :assessment_id),
      :assessment__survey_begin,
    ]

    accessions = base_query
                   .join(:accession, :id => :assessment_rlshp__accession_id)
                   .select(*(base_selection + [Sequel.as(:accession__display_string, :title),
                                               Sequel.as('accession', :record_type)]))

    resources = base_query
                   .join(:resource, :id => :assessment_rlshp__resource_id)
                   .select(*(base_selection + [Sequel.as(:resource__title, :title),
                                               Sequel.as('resource', :record_type)]))

    archival_objects = base_query
                   .join(:archival_object, :id => :assessment_rlshp__archival_object_id)
                   .select(*(base_selection + [Sequel.as(:archival_object__display_string, :title),
                                               Sequel.as('archival_object', :record_type)]))

    digital_objects = base_query
                        .join(:digital_object, :id => :assessment_rlshp__digital_object_id)
                        .select(*(base_selection + [Sequel.as(:digital_object__title, :title),
                                                    Sequel.as('digital_object', :record_type)]))


    accessions.union(resources).union(archival_objects).union(digital_objects).order(:survey_begin)
  end

end