# Mithril AutoForm
aldeed:autoform alike library for meteor developers with mithril frontend

## Quickstart
```
$ git clone https://github.com/rikyperdana/mithril-autoform
$ cd mithril-autoform
$ meteor npm install
$ meteor
```
And head to http://localhost:3000

## Description
This is a reverse-engineered version of aldeed:autoform, a meteor package that helps developers auto-create
form and it's functionality simply by defining a collection's schema. Most used features of aldeed:autoform
can be found in this repo. So, if you are already familiar with aldeed:autoform, you'll know how to use this repo.
But even if you're not, you still can keep up rather easily


aldeed:autoform are built specifically for meteor which use blaze templating engine for front-end renderer. While
people are steadily moving to vdom turf, it's not easy to find a comparable auto form generator for latest
stacks such as react, vuejs, or other vdom libs. But I've worked with mithriljs for couple of projects and decided
to create an aldeed:autoform alike library to help me deal with forms, and I hope it helps you too.

## How to use
You can remove (client, server, both).ls and replace it with your own `myCode.ls` like these:
```ls
myColl = new Meteor.Collection \myColl
mySchema = new SimpleSchema do
	name: type: String
	age: type: Number
	address: type: String

if Meteor.isClient
	m.mount document.body, view: ->
		m \.row, m autoForm do
			collection: myColl
			schema: mySchema
			type: \insert
			id: \myForm
```
It will render a form that contains the specified fields with insert behavior which you can test right away.
Once the values submited, you can check `meteor mongo` in your terminal to see the inserted data.

## APIs
autoForm is a function that accepts an objects with props like these:
* `collection`: accept your collection instance. (Required)
* `schema`: accept the schema you want to test the values against and build a form from it. (Required)
* `type`: accept either `\insert`, or `\update`, or `\method`, or `\update-pushArray`. (Required)
* `id`: a unique name for your generated form. (Required)
* `buttonContent`: the text to put in your submit button, default: `\submit`
* `buttonClasses`: the classes to put in your submit button, ex: `'orange right waves-effect'`
* `fields`: an array of strings of field name you'd want to include in your form
* `omitFields`: an array of strings of field name you'd want to exclude from your form
* `meteormethod`: a server method to be called if `type` prop is `\method`. The server method will receive an object containing the submited values as a callback
* `doc`: a document from the collection which will be updated by the generated form
* `scope`: if you use `\update-pushArray`, return the name of the field that contains the array you want to push to
* `autosave`: return `true` if you want to validate whenever form contents changes. Default is `false`
* `hooks`: some functions that can be called before or after form submission
  * `before: (doc, cb) ->` receive `doc` object that contains submitted form values and return it as `cb` parameter after your modification of the `doc` object
  * `after: (doc) ->` after autoForm successfully inserted the submitted form values, the `doc` object will be returned

## Known Issues
* Continuous m.redraw! makes you can't use tab key to move to the next field

## Further Development
* Inclusion of autoTable generator

## Contribution
You can freely fork this repo and get or make the best out of it.
