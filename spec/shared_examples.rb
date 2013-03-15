describe ActiveRecordInlineSchema do
  before do
    ActiveRecord::Base.descendants.each do |active_record|
      ActiveRecord::Base.connection.drop_table active_record.table_name rescue nil
    end
  end

  describe :regressions do
    def assert_unique(model, column_name, v, e = ActiveRecord::RecordNotUnique)
      lambda do
        2.times do
          p = model.new
          p.send "#{column_name}=", v
          p.save!
        end
      end.must_raise(e)
    end

    it "properly creates tables with only one column, an auto-increment primary key" do
      e = if sqlite?
        ActiveRecord::StatementInvalid
      else
        ActiveRecord::RecordNotUnique
      end
      Pet3.auto_upgrade!
      assert_unique Pet3, :id, 1, e
    end

    it "properly creates with only one column, a string primary key" do
      Pet4.auto_upgrade!
      assert_unique Pet4, :name, 'Jerry'
    end

    it "properly creates with only one column, a non-auto-increment integer primary key" do
      Pet5.auto_upgrade!
      assert_unique Pet5, :id, 1
    end

    it "properly registers non-incrementing integer primary keys" do
      Pet2.auto_upgrade!
      assert_unique Pet2, :id, 1
    end
  end

  it "supports boolean columns" do
    Pet6.auto_upgrade!
    Pet6.columns_hash['yesno'].type.must_equal :boolean
  end

  it "deletes unrecognized columns by default" do
    Pet6.auto_upgrade!
    ActiveRecord::Base.connection.add_column Pet6.table_name, 'foo', :string
    Pet6.safe_reset_column_information
    Pet6.column_names.must_include 'foo'
    Pet6.auto_upgrade!
    Pet6.column_names.wont_include 'foo'
  end

  it "deletes unrecognized columns by default" do
    Pet6.auto_upgrade!
    ActiveRecord::Base.connection.add_index Pet6.table_name, 'yesno', :name => 'testtest'
    Pet6.safe_reset_column_information
    Pet6.db_indexes.must_include 'testtest'
    Pet6.auto_upgrade!
    Pet6.db_indexes.wont_include 'testtest'
  end

  it "doesn't delete unrecognized columns in gentle mode" do
    Pet6.auto_upgrade!
    ActiveRecord::Base.connection.add_column Pet6.table_name, 'foo', :string
    Pet6.safe_reset_column_information
    Pet6.column_names.must_include 'foo'
    Pet6.auto_upgrade! :gentle => true
    Pet6.column_names.must_include 'foo'
    Pet6.columns_hash['foo'].type.must_equal :string
  end

  it "doesn't delete unrecognized columns in gentle mode" do
    Pet6.auto_upgrade!
    ActiveRecord::Base.connection.add_index Pet6.table_name, 'yesno', :name => 'testtest'
    Pet6.safe_reset_column_information
    Pet6.db_indexes.must_include 'testtest'
    Pet6.auto_upgrade! :gentle => true
    Pet6.db_indexes.must_include 'testtest'
  end

  it 'has #key,col,property,attribute inside model' do
    (!!ActiveRecord::Base.connection.table_exists?(Post.table_name)).must_equal false
    (!!ActiveRecord::Base.connection.table_exists?(Category.table_name)).must_equal false
    Post.auto_upgrade!; Category.auto_upgrade!
    Post.column_names.sort.must_equal Post.db_columns
    Category.column_names.sort.must_equal Category.schema_columns

    # Check default properties
    category = Category.create(:title => 'category')
    post = Post.create(:title => 'foo', :body => 'bar', :category_id => category.id)
    post = Post.first
    post.title.must_equal 'foo'
    post.body.must_equal 'bar'
    post.category.must_equal category
  end

  it 'has indexes inside model' do
    # Check indexes
    Animal.auto_upgrade!
    Animal.db_indexes.size.must_be :>, 0
    Animal.db_indexes.must_equal Animal.schema_indexes

    indexes_was = Animal.db_indexes

    # Remove an index
    target = indexes_was.pop
    Animal.inline_schema_config.ideal_indexes.delete_if { |ideal_index| ideal_index.name.to_s == target.to_s }
    Animal.auto_upgrade!
    Animal.schema_indexes.sort.must_equal indexes_was
    Animal.db_indexes.must_equal indexes_was

    # Add a new index
    Animal.class_eval do
      col :category_id, :type => :integer
      add_index :category_id
    end
    Animal.auto_upgrade!
    Animal.db_columns.must_include "category_id"
    Animal.db_indexes.must_equal((indexes_was << "index_animals_on_category_id").sort)
  end

  it 'works with STI' do
    Pet.auto_upgrade!
    Pet.safe_reset_column_information
    Pet.db_columns.must_include "type"
    Dog.auto_upgrade!
    Pet.db_columns.must_include "type"

    # Now, let's we know if STI is working
    Pet.create(:name => "foo")
    Dog.create(:name => "bar")
    Dog.count.must_equal 1
    Dog.first.name.must_equal "bar"
    Pet.count.must_equal 2
    Pet.all.map(&:name).must_equal ["foo", "bar"]

    # Check that this doesn't break things
    Cat.auto_upgrade!
    Dog.first.name.must_equal "bar"

    # What's happen if we change schema?
    Dog.schema_indexes.must_equal Pet.schema_indexes
    Dog.class_eval do
      col :bau
    end
    Dog.auto_upgrade!
    Pet.db_columns.must_include "bau"
    Dog.new.must_respond_to :bau
    Cat.new.must_respond_to :bau
  end

  it 'works with custom inheritance column' do
    User.auto_upgrade!
    User.inheritance_column.must_equal 'role' # known to fail on rails 3
    Administrator.create(:name => "Davide", :surname => "D'Agostino")
    Customer.create(:name => "Foo", :surname => "Bar")
    Administrator.count.must_equal 1
    Administrator.first.name.must_equal "Davide"
    Customer.count.must_equal 1
    Customer.first.name.must_equal "Foo"
    User.count.must_equal 2
    User.find_by_name('Davide').role.must_equal "Administrator"
    User.find_by_name('Foo').role.must_equal "Customer"
  end

  it 'allow multiple columns definitions' do
    Fake.auto_upgrade!
    Fake.create(:name => 'foo', :surname => 'bar', :category_id => 1, :group_id => 2)
    fake = Fake.first
    fake.name.must_equal 'foo'
    fake.surname.must_equal 'bar'
    fake.category_id.must_equal 1
    fake.group_id.must_equal 2
  end
  
  it 'allows non-integer primary keys' do
    Vegetable.auto_upgrade!
    Vegetable.primary_key.must_equal 'latin_name'
  end
  
  it 'properly creates primary key columns so that ActiveRecord uses them' do
    Vegetable.auto_upgrade!
    Vegetable.delete_all
    n = 'roobus roobious'
    v = Vegetable.new; v.latin_name = n; v.save!
    Vegetable.find(n).must_equal v
  end
  
  it 'automatically shortens long index names' do
    AutomobileMakeModelYearVariant.auto_upgrade!
    AutomobileMakeModelYearVariant.db_indexes.first.start_with?('index_automobile_make_model_ye').must_equal true
  end
  
  it 'properly creates primary key columns that are unique' do
    Vegetable.auto_upgrade!
    Vegetable.delete_all
    n = 'roobus roobious'
    v = Vegetable.new; v.latin_name = n; v.save!
    if sqlite?
      flunk # segfaults
      # lambda { v = Vegetable.new; v.latin_name = n; v.save! }.must_raise(SQLite3::ConstraintException)
    else
      lambda { v = Vegetable.new; v.latin_name = n; v.save! }.must_raise(ActiveRecord::RecordNotUnique)
    end
  end
  
  it 'properly creates tables with one column, a string primary key' do
    Gender.auto_upgrade!
    Gender.column_names.must_equal ['name']
  end
  
  it 'is idempotent' do
    ActiveRecord::Base.descendants.each do |active_record|
      active_record.auto_upgrade!
      active_record.safe_reset_column_information
      before = [ active_record.db_columns, active_record.db_indexes ]
      active_record.auto_upgrade!
      active_record.safe_reset_column_information
      [ active_record.db_columns, active_record.db_indexes ].must_equal before
      active_record.auto_upgrade!
      active_record.safe_reset_column_information
      active_record.auto_upgrade!
      active_record.safe_reset_column_information
      active_record.auto_upgrade!
      active_record.safe_reset_column_information
      [ active_record.db_columns, active_record.db_indexes ].must_equal before    
    end
  end

  case ENV['DB_ADAPTER']
  when 'mysql'
    it "takes custom types" do
      CustomMysql.auto_upgrade!
      CustomMysql.columns_hash['varb'].sql_type.must_equal 'varbinary(255)'
      CustomMysql.columns_hash['varc'].sql_type.must_equal 'varchar(255)'
    end
  when 'postgresql'
    it "takes custom types" do
      CustomPostgresql.auto_upgrade!
      CustomPostgresql.columns_hash['inet'].sql_type.must_equal 'inet'
      CustomPostgresql.columns_hash['bytea'].sql_type.must_equal 'bytea'
    end
  end
  
  private
  
  def sqlite?
    ActiveRecord::Base.connection.adapter_name =~ /sqlite/i
  end
end
