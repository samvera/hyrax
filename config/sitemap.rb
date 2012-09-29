# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
