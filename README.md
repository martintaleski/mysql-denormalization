## Mysql Denormalization Examples

### One To Many Example

`one-to-many.sql` is dump from an example database that shows how to denormalize a typical 1:N relation between blog article and article image tables. 

There is a denormalization procedure that is called by triggers on INSERT,UPDATE and DELETE on the `article_image` table. 

The image data is stored in a `images` field in json format on the `article` table. 

At the bottom of the file there are several inserts that will fill the database with example data to ilustrate the denormalized relation.
