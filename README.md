# ActiveRecordInlineSchema

Define table structure (columns and indexes) inside your ActiveRecord models like you can do in migrations. Also similar to DataMapper inline schema syntax.

Specify columns like you would with ActiveRecord migrations and then run .auto_upgrade! Based on the mini_record gem from Davide D'Agostino, it adds fewer aliases, doesn't create timestamps and relationship columns automatically.

## Production use

Over 2 years in [Brighter Planet's environmental impact API](http://impact.brighterplanet.com) and [reference data service](http://data.brighterplanet.com).

Lots and lots of use in the [`earth` library](https://github.com/brighterplanet/earth).

## Examples

    class Breed < ActiveRecord::Base
      col :species_name
      col :weight, :type => :float
      col :weight_units
    end
    Breed.auto_upgrade!

    class Airport < ActiveRecord::Base
      self.primary_key = "iata_code"
      belongs_to :country, :foreign_key => 'country_iso_3166_code', :primary_key => 'iso_3166_code'
      col :iata_code
      col :name
      col :city
      col :country_name
      col :country_iso_3166_code
      col :latitude, :type => :float
      col :longitude, :type => :float
    end
    Airport.auto_upgrade!

    class ApiResponse < ActiveRecord::Base
      col :raw_body, :type => 'varbinary(16384)'
    end
    ApiResponse.auto_upgrade!

## Credits

Massive thanks to DAddYE, who you follow on twitter [@daddye](http://twitter.com/daddye) and look at his site at [daddye.it](http://www.daddye.it)

## TODO

* merge back into mini_record? they make some choices (automatically creating relationships, mixing in lots of aliases, etc.) that I don't need
* make the documentation as good as mini_record

## History

Forked from [`mini_record` version v0.2.1](https://github.com/DAddYE/mini_record) - thanks @daddye! Here's a rough outline of the differences:

### Difference between mini_record v0.2.1 and active_record_inline_schema v0.4.0

Having diverged at [this commit](https://github.com/DAddYE/mini_record/commit/55b2545f9772f7500d3782ac530b3da456f50023), I did stuff like...

* didn't set primary key on table definition
* allow custom column types
* removed aliases
* shorten name with zlib trick
* allow passing create_table_options
* default to ENGINE=InnoDB on mysql
* detect and create table for non-standard primary key
* move where schema inheritance columns are defined
* removed table_definition accessor
* allow custom column types like `varbinary`
* more compatible with ActiveRecord 3.0 and 3.2.2

### Difference between mini_record v0.2.1 and mini_record v0.3.0

After I made this list, I decided to diverge from mini_record instead of doing a pull request:

* allow custom column types
* add timestamps
* remove unused (unmentioned) tables
* call auto_upgrade on descendant tables
* automagically generate fields from associations
* revised difference checking code

Pity the forker (me)!

## Copyright

Copyright 2012 Seamus Abshere

Adapted from [mini_record](https://github.com/DAddYE/mini_record), which is copyright 2011 Davide D'Agostino

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the “Software”), to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
