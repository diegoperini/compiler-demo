require('coffeescript/register')

let typeTables = require('./type-tables')
let propertyTables = require('./property-tables')
let functionTables = require('./function-tables')

module.exports = { ...typeTables, ...propertyTables, ...functionTables }
