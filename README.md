# Grithin's Jquery Enhancements

## What

Various general use extensions I've written on jquery

## Examples
```coffee
# Extract data from form
$('form').extractInput()

# fill the inputs in a form with the keyed data provided
$.fn.fillInputs(values)

# apply function to text of element
$('div').toSelf(_.capitalize)

# get the outerHTML of an element, regardless of whether it is attached to the DOM
$('div').outerHTML()

# include css/js once
$.include_once(url)
```