fs = require 'fs'
path = require 'path'
consola = require 'consola'

pkg = require '../package.json'
PREFIX = "[#{pkg.name}]"

resolveSourceFile = (jsFile, config) ->
  cwd = process.cwd()
  outDir = path.resolve cwd, config.output
  entryPath = path.resolve cwd, config.entry

  try
    if fs.statSync(entryPath).isFile()
      return entryPath
  catch
    return null

  relative = path.relative outDir, jsFile
  srcRelative = relative.replace /\.js$/, '.coffee'
  srcFile = path.join entryPath, srcRelative

  if fs.existsSync srcFile
    return srcFile

  return null

addShebang = (options = {}) ->
  return (compilationResult) ->
    consola.info "#{PREFIX} Running..."

    { compiledFiles, config } = compilationResult

    if config.options?.join
      consola.info "#{PREFIX} Option `join` is enabled. Skipping shebang addition."
      return

    unless compiledFiles and compiledFiles.length > 0
      consola.warn "#{PREFIX} No compiled files found."
      return

    processedCount = 0

    for jsFile in compiledFiles
      continue unless jsFile.endsWith '.js'

      try
        srcFile = resolveSourceFile jsFile, config
        unless srcFile
          continue

        srcContent = fs.readFileSync srcFile, 'utf-8'
        firstLine = srcContent.split('\n')[0].trim()

        if firstLine.startsWith '#!'
          jsContent = fs.readFileSync jsFile, 'utf-8'
          unless jsContent.startsWith '#!'
            newContent = firstLine + '\n' + jsContent
            fs.writeFileSync jsFile, newContent, 'utf-8'

            consola.trace "#{PREFIX} Added shebang to #{path.basename jsFile}: #{firstLine}"
            processedCount++

      catch error
        consola.error "#{PREFIX} Failed to process #{jsFile}:", error

    if processedCount > 0
      consola.success "#{PREFIX} Added shebang lines to #{processedCount} file(s)."
    else
      consola.info "#{PREFIX} No files needed shebang addition."

module.exports = addShebang
