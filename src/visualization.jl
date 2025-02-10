function display_mp4(filename)
    display("text/html", string("""<video autoplay controls><source src="data:video/x-m4v;base64,""",
        base64encode(open(read, filename)), """" type="video/mp4"></video>"""))
end
