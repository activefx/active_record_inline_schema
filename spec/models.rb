# be sure to set up activerecord before you require this helper

class Person < ActiveRecord::Base
  include SpecHelper
  col :name
end

class Post < ActiveRecord::Base
  include SpecHelper

  col :title
  col :body
  col :category_id, :type => :integer
  belongs_to :category
end

class Category < ActiveRecord::Base
  include SpecHelper

  col :title
  has_many :posts
end

class Animal < ActiveRecord::Base
  include SpecHelper

  col :name
  add_index :name
  add_index :id
  add_index [:name, :id]
end

class Pet < ActiveRecord::Base
  include SpecHelper

  col :name
  col :type
  add_index :name
end
class Dog < Pet; end
class Cat < Pet; end

class Vegetable < ActiveRecord::Base
  include SpecHelper

  self.primary_key = 'latin_name'
  
  col :latin_name
  col :common_name
end

class Gender < ActiveRecord::Base
  include SpecHelper

  self.primary_key = 'name'
  
  col :name
end

class User < ActiveRecord::Base
  self.inheritance_column = 'role'
  include SpecHelper
  col :name
  col :surname
  col :role
end
class Administrator < User; end
class Customer < User; end

class Fake < ActiveRecord::Base
  include SpecHelper
  col :name
  col :surname
  col :category_id, :type => :integer
  col :group_id, :type => :integer
end

class AutomobileMakeModelYearVariant < ActiveRecord::Base
  include SpecHelper
  col :make_model_year_name
  add_index :make_model_year_name
end

class Pet2 < ActiveRecord::Base
  include SpecHelper
  self.primary_key = "id"
  col :id, :type => :integer
  col :name
end

class Pet3 < ActiveRecord::Base
  include SpecHelper
end

class Pet4 < ActiveRecord::Base
  include SpecHelper
  self.primary_key = "name"
  col :name
end

class Pet5 < ActiveRecord::Base
  include SpecHelper
  self.primary_key = "id"
  col :id, :type => :integer
end

class Pet6 < ActiveRecord::Base
  include SpecHelper
  col :yesno, :type => :boolean
end

case ENV['DB_ADAPTER']
when 'mysql'
  class CustomMysql < ActiveRecord::Base
    include SpecHelper
    col :varb, :type => 'varbinary(255)'
    col :varc, :type => 'varchar(255)'
  end
when 'postgresql'
  class CustomPostgresql < ActiveRecord::Base
    include SpecHelper
    col :inet, :type => 'inet'
    col :bytea, :type => 'bytea'
  end
end