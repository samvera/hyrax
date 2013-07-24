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

class CharacterizeJob

  def queue_name
    :characterize
  end

  attr_accessor :generic_file_id, :generic_file

  def initialize(generic_file_id)
    self.generic_file_id = generic_file_id
  end

  def run
    self.generic_file = GenericFile.find(generic_file_id)
    generic_file.characterize
    after_characterize
  end

  def after_characterize
    if generic_file.pdf? || generic_file.image? || generic_file.video?
      generic_file.create_thumbnail
    end
    if generic_file.video?
      Sufia.queue.push(TranscodeVideoJob.new(generic_file_id))
    elsif generic_file.audio?
      Sufia.queue.push(TranscodeAudioJob.new(generic_file_id))
    end
  end
end
