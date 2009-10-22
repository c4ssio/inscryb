module DefaultData
  
  def self.add_starting_data
    #add group members
    TermGroup.add_members(:name=> 'primary_things',:member=>["item","place"])
    TermGroup.add_members(:name=> 'match_key', :member => ["name","type","purpose"])
    TermGroup.add_members(:name=>'thing_key_child',
      :member => ["aboard","at","in","inside","on","part of","located in","within","into","along"])
    TermGroup.add_members(:name=> 'thing_key_parent', :member => ["of","has","with","without"])
    TermGroup.add_members(:name=> 'thing_key_up', :member => ["above","on","over","upon","up"])
    TermGroup.add_members(:name=> 'thing_key_through', :member => ["across","through","into","down"])
    
    TermGroup.add_members(:name=>'thing_key_forward',
      :member=>["across from","beyond","through","over","against","opposite","past","down",])
    
    TermGroup.add_members(:name=>'thing_key_beside',
      :member=>["through","against","along","around","beside","by","down"])

    TermGroup.add_members(:name=>'thing_key_middle',:member=>["amid","among","around","between","round"])
    
    TermGroup.add_members(:name=>'thing_key backward',:member=>"behind")
    
    TermGroup.add_members(:name=>'thing_key_down',:member=>["below","beneath","under","underneath"])
    
    TermGroup.add_members(:name=>'thing_key_outside',:member=>"outside")

    TermGroup.add_members(:name=>'thing_key_origin',:member=>"from")
    
    TermGroup.add_members(:name=>'thing_key_target',:member=>["to","toward"])

    TermGroup.add_members(:name=>'thing_key_owner_current',
      :member=>["property of","belongs to","owned by","has","my","his","their","her","its","owner of"])

    TermGroup.add_members(:name=>'thing_key_owner_prior',:member=>"from")
    
    TermGroup.add_members(:name=>'thing_key_owner_next',:member=>["for"])

    TermGroup.add_members(:name=>'thing_key_distance_time',
      :member=>["after","before","during","at","on","near","far from","following","until"])

    TermGroup.add_members(:name=>'thing_key_distance_space',
      :member=>["after","before","via","at","on","near","far from","following","until"])
    
    TermGroup.add_members(:name=>'thing_key_comp_subj',:member=>["about","concerning","regarding"])
    
    TermGroup.add_members(:name=>'thing_key_comp_similar',:member=>["like","unlike"])
    
    TermGroup.add_members(:name=>'thing_key_comp_dissimilar',:member=>["anti","versus"])
    
    TermGroup.add_members(:name=>'forbidden_misc',
      :member=>["besides","but","minus","off","onto","per","plus","save","since","than","considering","despite","except","excepting","excluding"])

    #Owner_email group
    TermGroup.add_members(:name=>'email',
      :member=>["cust_service_email","legal_email","deliveries_email","feedback_email","user_email","purchase_email"])
  
    #add thing key group group
    TermGroup.add_members(:name=> 'thing_key_',
      :member=>["thing_key_child","thing_key_parent","thing_key_up",
        "thing_key_through","thing_key_forward","thing_key_beside",
        "thing_key_middle","thing_key_backward","thing_key_down",
        "thing_key_outside","thing_key_origin","thing_key_target",
        "thing_key_owner_current","thing_key_owner_prior","thing_key_owner_next",
        "thing_key_distance_time","thing_key_distance_space",
        "thing_key_comp_subj","thing_key_comp_similar","thing_key_comp_dissimilar"])

    ['item','place'].each do |v|
      ThingType.find_or_create_by_value(v)
    end

  end
end