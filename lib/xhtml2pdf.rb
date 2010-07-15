# ActsAsFlyingSaucer
#
module ActsAsFlyingSaucer

  # Xhtml2Pdf
  #
  class Xhtml2Pdf

    # Xhtml2Pdf.write_pdf
    #
    def self.write_pdf(options)
      if options[:io_out]
        options[:file_name] = "pdf_file.pdf" unless options[:file_name]
        options[:file_name] += ".pdf" unless options[:file_name].ends_with?(".pdf")
        input_file = Tempfile.new("pdf_htmlinput")
        input_file << options[:html]
        input_file.close
        output_file = Tempfile.new("pdf_output")
        options.merge!({:output_file => output_file.path, :input_file => input_file.path}).merge!(ActsAsFlyingSaucer::Config.options)
      else
        File.open(options[:input_file], 'w') do |file|
          file << options[:html]
        end
      end
      if defined?(JRUBY_VERSION)
        input = options[:input_file]
        output = options[:output_file]
        url = java.io.File.new(input).toURI.toURL.toString

        os = java.io.FileOutputStream.new(output)

        renderer = org.xhtmlrenderer.pdf.ITextRenderer.new
        renderer.setDocument(url)
        renderer.layout
        renderer.createPDF(os)
        os.close
      else
        java_dir = File.join(File.expand_path(File.dirname(__FILE__)), "java")

        class_path = ".:#{java_dir}/bin"

        Dir.glob("#{java_dir}/jar/*.jar") do |jar|
          class_path << "#{options[:classpath_separator]}#{jar}"
        end

        command = "#{options[:java_bin]} -Xmx512m -Djava.awt.headless=true -cp #{class_path} Xhtml2Pdf #{options[:input_file]} #{options[:output_file]}"
        system(command)
      end
      if options[:io_out]
        io_output = PdfIO.new(options[:file_name], output_file)
        # cleanup
        output_file.close(true)
        input_file.unlink
        return io_output
      end
    end

    def self.encrypt_pdf(options,output_file_name,password)
      java_dir = File.join(File.expand_path(File.dirname(__FILE__)), "java")

      class_path = ".:#{java_dir}/bin"

      Dir.glob("#{java_dir}/jar/*.jar") do |jar|
        class_path << "#{options[:classpath_separator]}#{jar}"
      end

      command = "#{options[:java_bin]} -Xmx512m -Djava.awt.headless=true -cp #{class_path} encryptPdf #{options[:output_file]} #{output_file_name} #{password}"
      system(command)
    end

  end

  class PdfIO < StringIO
    attr_accessor :original_filename, :size, :content_type
    def initialize(file_name, file)
      @original_filename, @size, @content_type = file_name, file.size, "application/pdf"
      content = file.read
      super(content)
    end
  end
end
