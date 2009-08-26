require 'ed'
require 'db'

def get_onefile_cases(basename)
  testfile = basename + '.test'
  if !File.exist?(testfile)
    return nil
  end

  puts "Loading testcases from #{testfile}"
  t = File.read(testfile)
  testcases = []
  while t.sub!(/(.*?)\n__INPUT__\n/m, '')
    i = $1
    if !t.sub!(/(.*?)\n__OUTPUT__\n/m, '')
      raise "malformed test description file"
    end
    o = $1
    testcases << [i, o]
  end

  # use codegolf's evaluation by default
  type = :cg
  if t =~ /ag/
    type = :ag
  elsif t =~ /exact/
    type = :exact
  end

  [type, testcases]
end

def get_files_cases(basepath)
  files = Dir["#{basepath}*.output"].sort
  if files.empty?
    return nil
  end

  puts "Loading testcases from #{basepath}*"
  testcases = []
  files.each do |file|
    o = File.read(file)
    input_file = File.join(File.dirname(file),
                           File.basename(file, '.output') + '.input')
    i = ''
    if File.exist?(input_file)
      i = File.read(input_file)
    end
    testcases << [i, o]
  end

  [:cg, testcases]
end

def get_ag_cases(basename, problem)
  if problem
    update_file2problem(basename, problem)
  else
    problem = file2problem(basename)
  end
  dummy, problem = ag_unescape(problem).split('?')
  puts "Loading testcases of '#{problem}'"
  db = db_ag(problem + '.db')

  testcases = []
  testcases << [db['input'].to_s, db['output'].to_s]
  if db['output2'].to_s != '' || db['input2'].to_s != ''
    testcases << [db['input2'].to_s, db['output2'].to_s]
  end
  if db['output3'].to_s != '' || db['input3'].to_s != ''
    testcases << [db['input3'].to_s, db['output3'].to_s]
  end

  [:ag, testcases]
end

def get_testcases(basename, problem)
  if !problem
    r = get_onefile_cases(basename)
    return r if r
    r = get_files_cases(File.join('test', basename))
    return r if r
    r = get_files_cases(File.join(SRC_DIR, 'cg', basename))
    return r if r
  end
  get_ag_cases(basename, problem)
end
