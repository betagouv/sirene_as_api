require 'open-uri'

class DownloadFile < SireneAsAPIInteractor
  around do |interactor|
    
    stdout_info_log "Attempting to download #{filename}"
    
    context.filepath = "./tmp/files/#{filename}"
    context.filename = filename

    if File.exist?(context.filepath)
      stdout_warn_log "#{filename} already exists ! Skipping download"
    else
      interactor.call
      stdout_success_log "Downloaded #{filename} successfuly"
    end

    puts
  end

  def call
    download = open(context.link)
    IO.copy_stream(download, context.filepath)
  end

  private

  def filename
    # We add the date before .csv.gz on the file so monthly stocks have different names
    if (current_month == '01')
      return URI(context.link).path.split('/').last.insert(-8, '_' + last_year + '_12')
    else
      return URI(context.link).path.split('/').last.insert(-8, '_' + current_year + '_' + last_month)
    end
  end
end
