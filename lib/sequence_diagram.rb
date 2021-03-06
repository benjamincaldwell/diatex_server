require 'charts'

module SequenceDiagram
  def convert_mermaid_to_png(content)
    if content.strip.start_with?('gantt')
      gantt_chart(content)
    else
      mermaid_chart(content)
    end
  end

  def gantt_chart(content)
    final_image = "#{Application.constants[:TEMP_MERMAID]}/#{Time.now.to_i}.png"
    Application.logger.info("saving gant chart to #{final_image}")
    Dir.mktmpdir do |dir|
      Charts.render_chart(content, File.join(dir, 'chart.svg'))
      output = `convert #{File.join(dir, 'chart.svg')} #{File.join(dir, 'chart.png')}`
      return [false, output] if $?.exitstatus != 0
      FileUtils.mv(File.join(dir, 'chart.png'), final_image)
    end
    [true, final_image]
  end

  def mermaid_chart(content)
    uid = Digest::MD5.hexdigest(content)
    file = Tempfile.new([uid, '.mmd'])
    file.write(content)
    file.flush

    cmd = "mermaid #{file.path} --png --outputDir #{Application.constants[:TEMP_MERMAID]}"
    Application.logger.info "Running `#{cmd}`"
    output = `#{cmd}`
    file.close
    return [false, output] if $?.exitstatus != 0

    files = Dir["#{Application.constants[:TEMP_MERMAID]}/#{uid}*.png"]
    Application.logger.info "Mermaid made a file at #{files.inspect}"
    return [false, output] if files.empty?

    [true, files.first]
  end
end
