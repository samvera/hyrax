at_exit do 
  Batch.find(:all, :rows=>Batch.count).map(&:delete)
  GenericFile.find(:all, :rows=>GenericFile.count).map(&:delete)
end
