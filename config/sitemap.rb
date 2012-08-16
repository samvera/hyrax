Sitemap::Generator.instance.load host: 'scholarsphere.psu.edu' do
  path :root, priority: 1, change_frequency: 'daily'
  path :catalog_index, priority: 1, change_frequency: 'daily'
  User.all.each do |user|
    path :profile, params: { uid: user.login }, priority: 0.8, change_frequency: 'daily'
  end
  GenericFile.find('access_group_t' => 'public').each do |gf|
    path :generic_file, params: { id: gf.noid }, priority: 1, change_frequency: 'weekly'
  end

  # TODO: figure out why these don't work as expected
  #path :static, params: { action: 'about' }, priority: 0.7, change_frequency: 'monthly'
  #path :static, params: { action: 'help' }, priority: 0.6, change_frequency: 'monthly'
  #path :static, params: { action: 'terms' }, priority: 0.2, change_frequency: 'monthly'
end
