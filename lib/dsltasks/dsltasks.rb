module DSLTasks

  module TaskMixin
    attr_reader :__block__
    attr_reader :__name__
    attr_reader :__parent_task__
    attr_reader :__lib_stack__
    attr_reader :__lib_dirs__
    def __initialize_task_mixin__(opts={})
      @__parent_task__ = opts[:parent]
      @__name__ = opts[:name]
      @__block__ = opts[:block]
      @__lib_stack__ = opts[:lib_stack]
      @__lib_dirs__ = opts[:lib_dirs] || (opts[:parent] ? opts[:parent].__lib_dirs__ : [])
      @__root__ = opts[:root] || self
      @__tasks__ = Hash.new
    end
    def __exec__(calling_task, args, block)
      rvalue = nil
      task_stack = DSLTasks::task_stack(@__root__)
      task_stack.push self
      unless block.nil?
        args << block
      end
      rvalue = instance_exec(*args, &@__block__)
      task_stack.pop
      return rvalue
    end
    def __caller__()
      (DSLTasks::task_stack(@__root__))[-2]
    end
    def lib(lib_name)
      lib_name = lib_name.to_s
      if lib_name.start_with?('/')
        if File.exist?(lib_name)
          unless @__lib_stack__.include?(fname)
            @__lib_stack__.push(File.expand_path(lib_name))
            instance_eval(File.read(lib_name), File.expand_path(lib_name))
            @__lib_stack__.pop
          end
        else
          raise "Lib file not found: #{lib_name}"
        end
      else
        # search path if not absolute:
        #   directory of file of task from which lib was called
        #   directories in @__lib_dirs__, in order
        dirnames = [File.dirname(@__lib_stack__[-1]), *@__lib_dirs__]
        fnames = dirnames.map {|d| File.join(d, lib_name)}
        fnames.map! {|f| f.end_with?('.rb') ? f : f+'.rb'}
        found_lib = false
        fnames.each do |fname|
          if File.exist?(fname)
            unless @__lib_stack__.include?(fname)
              @__lib_stack__.push(File.expand_path(fname))
              instance_eval(File.read(fname), File.expand_path(fname))
              @__lib_stack__.pop
            end
            found_lib = true
            break
          end
        end
        if !found_lib
          raise "Lib file not found in possible locations: #{fnames.join(',')}"
        end
      end
    end
    def run_task(name, *args, block)
      if @__tasks__.has_key?(name.to_sym)
        task = @__tasks__[name.to_sym]
        return task.__exec__(self, args, block)
      elsif @__parent_task__
        return @__parent_task__.run_task(name, *args, block)
      else
        raise "Unrecognized task: #{name}"
      end
    end
    def task(name, &block)
      if block.nil?
        if @__tasks__.has_key?(name.to_sym)
          return @__tasks__[name.to_sym]
        end
      else
        @__tasks__[name.to_sym] = Task.new(parent: self, lib_stack: @__lib_stack__.clone, name: name.to_sym, block: block, root: @__root__)
      end
    end
    def method_missing(name, *args, &block)
      run_task(name, *args, block)
    end
    def respond_to_missing?(name, *args)
      if @__tasks__.has_key?(name.to_sym)
        return true
      elsif @__parent_task__
        return @__parent_task__.respond_to_missing?(name, *args)
      else
        return false
      end
    end
  end

  class Task
    include TaskMixin
    def initialize(*args)
      __initialize_task_mixin__(*args)
    end
  end

  class DSLTaskContext
    include TaskMixin

    def initialize(base_file, lib_dirs=nil)
      @__task_context__ = Hash.new
      __initialize_task_mixin__(lib_stack: [base_file], lib_dirs: lib_dirs)
    end

    def execute(main, libs)

      __lib_stack__.push(main) 
      (libs || []).each do |l|
        lib l
      end
      __lib_stack__.pop

      instance_eval(File.read(main), main)
    end
  end

  module_function

  def task_stack(root)
    @task_stacks ||= Hash.new {|h,k| h[k] = []}
    return @task_stacks[root]
  end
  private :task_stack

  def start(opts=nil)
    lib_dirs = opts[:lib_dirs] || []
    file = opts[:main]
    if File.exist?(file)
      file = File.expand_path(file)
      context = DSLTaskContext.new(file, lib_dirs)
      context.execute(file, opts[:libs])
    else
      raise "File not found: #{file}"
    end
  end

end
