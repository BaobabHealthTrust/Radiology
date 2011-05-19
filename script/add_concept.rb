# Run this with script runner: script/runner script/fake_concept [name] [id]
  User.current_user = User.find_by_username("admin")
  Location.current_location = Location.current_health_center

  def add(name)
    id = Concept.find(:last,:order =>'concept_id DESC').concept_id + 1
    concept = Concept.new()
    #concept.concept_id = id
    concept.class_id = 7
    concept.datatype_id = 3
    concept.is_set = 0
    concept.save
    puts ">>> #{id} #{name}"
   
    concept_name = ConceptName.new()
    concept_name.concept_id = concept.id
    concept_name.name = name
    concept_name.save
  end

  add('LIMB TYPE')

