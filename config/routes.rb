ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "things"

  map.add_tag '/things/:id/add_tag/', :controller=>'things', :action=>'add_tag', :conditions => {:method => :post}
  map.delete_tag '/things/:id/delete_tag/', :controller=>'things', :action=>'delete_tag', :conditions => {:method => :post}
  map.clip '/things/:id/clip/', :controller=>'things', :action=>'clip', :conditions => {:method => :post}
  map.add_thing '/things/:id/add_thing/', :controller=>'things', :action=>'add_thing', :conditions => {:method => :post}
  map.refresh '/things/:id', :controller=>'things', :action=>'refresh', :conditions => {:method => :post}
  map.rename_thing '/things/:id/rename_thing', :controller=>'things', :action=>'rename_thing', :conditions => {:method => :post}

  map.resources :things

  map.login 'users/login', :controller=>'users', :action=>'login', :conditions => {:method => :post}
  map.logout 'users/logout', :controller=>'users', :action=>'logout', :conditions => {:method => :post}

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'

end
