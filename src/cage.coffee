# Description:
#   TODO
#
# Dependencies:
#   None
#
# Commands:
#   hubot cage me <story_num> - Recite a story from John Cage's lecture 'Indeterminacy'.
#
# Author:
#   jfhamlin

select = require('soupselect').select
htmlparser = require('htmlparser')
http = require('http')
sys = require('sys')
Entities = require('html-entities').XmlEntities;
Iconv = require('iconv').Iconv

nodeToText = (node) ->
  if node.type is 'tag'
    return (nodeToText(child) for child in node.children).join(' ') if node.children
  else if node.type is 'text'
    return node.raw
  return ''

cageMe = (n, callback) ->
  path = "/indeterminacy/s/#{n}"
  host = 'www.lcdf.org'
  options =
    host: host,
    port: 80,
    path: path,
    method: 'GET'
  request = http.request options, (response) =>
    response.setEncoding 'utf-8'
    body = ''
    response.on 'data', (chunk) =>
      body = body + chunk

    response.on 'end', =>
      body = body.replace(/&nbsp;/g, " ")
      parser = new htmlparser.Parser(new htmlparser.DefaultHandler((err, dom) =>
        if not err
          paras = select dom, 'p'
          left_paras = paras.filter (p) ->
            return false if not p.attribs
            return p.attribs.align is 'left'
          text = (nodeToText(child) for child in left_paras[1].children).join('')
          entities = new Entities();
          iconv = new Iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE')
          text = iconv.convert(entities.decode(text)).toString()

          callback text))
      parser.parseComplete body

  request.end()

memoized = {}

module.exports = (robot) ->
  robot.respond /CAGE\s+ME(\s+(\d+))?$/i, (msg) ->
    number = (msg.match[2] or Math.floor(180 * Math.random())) % 180 + 1
    if memoized[number]
      msg.send memoized[number]
    else
      cageMe number, (text) =>
        memoized[number] = text
        msg.send text
