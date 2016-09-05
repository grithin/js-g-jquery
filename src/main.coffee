`global= (typeof(global) != 'undefined' && global)  || (typeof(window) != 'undefined' && window) || this`
$ = global.$ || global.jQuery || require('jquery')
global.$ = $


# turn form into flat object of keyed values like:
# {"start[bob]":"",  "start[sue]":"",  "end":"", ...}
$.fn.extractInput = ->
	data = {}
	# include children, and self (if self has [name])
	$('[name]', $(this)).addBack().filter('[name]').each ()->
		$e = $(this)
		name = $e.attr('name')
		# with a checkbox, it is either is off (false), or is on (takes the value of value="...")
		# However, since url-encode turns `false` into a string "false", need a better indicator -> empty string
		if $(this).attr('type') == 'checkbox'
			if $(this).prop('checked')
				value = $(this).val()
			else
				value = ''
		else
			value = $e.val()
		if data[name] == undefined
			data[name] = value
		else if data[name].push
			data[name].push value
		else
			data[name] = [data[name]].concat value
	data


$.fn.hasAttr = (name) ->
	if typeof @attr(name) != typeof undefined and @attr(name) != false
		return true
	false

#/jquery ajax post for json request and response.  the laziness is  strong with this one

###
	@overloading
		[options]
		[url, data]
		[url, data, successCallback]
	$.json({url:'/api', data:{bob:{sue:'moe'}}})
###

$.json = (options) ->
	if arguments.length > 1
		console.warn('$.json expects one argument, and obj')
	defaults =
		contentType: 'application/json'
		dataType: 'json'
		method: 'POST'
	if options.data and typeof options.data != 'string'
		options.data = JSON.stringify(options.data)
	options = _.defaults(options, defaults)

	$.ajax options

#/jquery ajax file post for json request and response

###*
@param	fileInputs	can be array of elements, or a
###

$.file = (options, fileInputs) ->
	data = new FormData
	if options.data
		data.append '_json', JSON.stringify(options.data)
	fileInputs.map (file, what) ->
		data.append $(file).attr('name'), file.files[0]
		return
	#jquery doesn't handle setting boundary, so use basic javascript
	options.url = options.url or window.location
	xhr = new XMLHttpRequest
	xhr.open 'POST', options.url
	xhr.send data
	xhr
	#xhr.setRequestHeader("X_FILENAME", file.name);

#apply fn to each ele matching selector (good for using bound arguments for later calls using bf.run)

###*
news.subscribe(
	'view-change',
	$.eachApply.arg('[data-timeAgo]',bf.view.ele.timeAgo))
###

$.eachApply = (selector, fn) ->
	$(selector).each fn
	return

#/causes  form to submit when pressing enter on an type="input" element (since without submit button, doesn't behave this way by default)

###*
@ex	$('form').setEnterSubmit()
###
$.fn.setEnterSubmit = ->
	$('input', $(this)).keypress (e) ->
		if e.which == 13
			$(this).submit()
		return
	return

# fill the inputs in a form with the keyed data provided
$.fn.fillInputs = (values) ->
	$('[name]:not([type="submit"])', $(this)).each ->
		name = $(this).attr('name')
		if values.hasOwnProperty(name)
			$(this).fillInput values[name]
		return
	return

# fill the input of `this` element depending upon the value, and depending upon input type (checkbox, select, etc)
$.fn.fillInput = (value)->
	if $(this).attr('type') == 'checkbox'
		if _.isArray(value)
			# handle case of list of checked values, wherein apply check if self.value within
			# first, conform to string
			value = value.map (v)-> v+''
			if value.indexOf($(this).val()) != -1
				$(this).prop('checked',true)
		else
			if value && value != '0'
				$(this).prop('checked',true)
	else
		$(this).val(value || '')

# clear named inputs at and within an element
$.fn.clearInputs = ->
	$('[name]', $(this)).addBack().filter('[name]').each ()->
		$el = $(this)
		if $el.attr('type') == 'checkbox'
			$el.prop 'checked', false
		else
			$el.val ''
	$el


$.fn.fillOptions = (options) ->
	for key of options
		$(this).append $('<option>').val(options[key][0]).text(options[key][1])
	return
# get all child text nodes
$.fn.childTexts = (whitespace) ->
	texts = []
	$(this).contents().filter(->
		@nodeType == 3
	).each ->
		texts.push _.trim($(this).text())
		return
	if !whitespace
		texts = _.remove(texts)
		#clear empty values
	texts
$.uniqueId = new ()->
	@ids = {}
	@get = ()=>
		id = 'unique-'+('' + Math.random())[2..]
		if @ids[id]
			return @get()
		if $('#unique-'+id).size()
			return @get()
		@ids[id] = true
		return id
	@is = (id)=>
		!!@ids[id]
	return
# if no id, create a unique id for the element
$.fn.uniqueId = ()->
	id = $(this).attr('id')
	if !id
		id = $.uniqueId.get()
		$(this).attr('id', id)
	return id
# get children that have no children, or self if self has none
# use `$('div').childless().first()` to get single
$.fn.childless = ()->
	if !$(this).children().length
		return $(this)
	return $('*:not(:has(*))', this) # all elements that don't hav children


# detach element, but keep track of where it was for re-attachment
$.fn.un_attach = ()->
	$(this).data('detached_from', $(this).parent())
	$(this).data('detached_index', $(this).index())
	$(this).detach()
# re-attach an un-attached element
$.fn.re_attach = ()->
	parent = $(this).data('detached_from')
	index = $(this).data('detached_index')
	sibling_before = $(':lt('+index+'):last', parent)
	if sibling_before.size()
		sibling_before.after $(this)
	else
		parent.append($(this))
# determine if an element is detached from the dom
$.fn.isDetached = ()->
	if $(this).data('detached_from')
		return true
	if $(this).parent().size()
		return false
	!$.contains(document, this)
# get the outerHTML of an element, regardless of whether it is attached to the DOM
$.fn.outerHTML = ()->
	if $(this)[0]
		return $(this)[0].outerHTML
	return $('<div>').append($(this).clone()).html()
# turn what might be html into a e$, or, if not, wrap it in <div>
$.conform = (possible_html)->
	e$ = $('<div>').html(possible_html)
	if e$.children().size()
		return e$.children().first()
	e$
# apply a function to self text
$.fn.toSelf = (fn)->
	$(this).text fn($(this).text())

# include css/js once
$.include_once = ((url)->
	if !@started # fill with existing loadeds
		@started = true
		that = @
		$('link').each ()-> that.included[$(this).attr('href')] = Promise.resolve()
		$('script').each ()-> that.included[$(this).attr('src')] = Promise.resolve()
	if !@included[url]
		extension = Url.parse(url).pathname.split('.').pop()
		if extension == 'js'
			@included[url] = $.ajax(dataType: "script", cache: true, url: url)
		else if extension == 'css'
			$('<link rel="stylesheet" type="text/css" >').attr('href', url).appendTo('body')
			@included[url] = Promise.resolve()
	return @included[url]
).bind(_.makeInstance(started: false, included: {}))

# get all elements, including self
$.fn.all = ()->
	$('*',$(this)).addBack()
# find the first element matching a filter, including searching the current element
$.fn.firstMatch = (selecter)->
	$(this).all().find(selecter).first()


# get current href or set it
$.fn.href = (link)->
	if arguments.length == 1
		return $(this).attr('href', link)
	else
		$(this).attr('href')
# get current id or set it
$.fn.id = (id)->
	if arguments.length == 1
		return $(this).attr('id', id)
	else
		$(this).attr('id')
###
[data-id] on self?  On a parent?  On a single child?
###
$.fn.dataId = ()->
	if $(this).hasAttr('data-id')
		return $(this).attr('data-id')
	contained = $(this).parents('[data-id]:first')
	if contained.size()
		return contained.attr('data-id')
	children = $(this).find('[data-id]')
	if children.size() == 1
		return children.attr('data-id')


# get value or text, with priority of value
$.fn.txt = (new_value)->
	if new_value == undefined
		if $(this).hasAttr('value')
			return $(this).attr('value')
		else
			return $(this).text()
	else
		if $(this).hasAttr('value')
			return $(this).attr('value', new_value)
		else
			return $(this).text(new_value)

$.fn.shown = ()->
	$(this).css('display') == 'none'