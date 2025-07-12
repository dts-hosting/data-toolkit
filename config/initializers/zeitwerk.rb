Rails.autoloaders.each do |autoloader|
  # This is excluded from zeitwerk autoloading because Mark does not
  #   want to follow the one-class-per-file requirement and Kristina
  #   finds it annoying to have to use Exceptions::MyError everywhere,
  #   which would be the effect of the other workaround allowing multiple
  #   classes in a file. The exceptions file is explicitly loaded at the
  #   bottom of config/application so that, for day-to-day development
  #   work, it FEELS like it has been autoloaded (we don't have to remember
  #   to require it in files that use an exception class).
  autoloader.ignore(Rails.root.join("app/exceptions").to_s)
end
