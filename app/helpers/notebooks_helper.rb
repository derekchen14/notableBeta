module NotebooksHelper

  def make_default_notebook
    tutorial = { "guid" => SecureRandom.uuid,
      "title" => "Notable Tutorial",
      "modview" => "outline",
      "user_id" => current_user.id }
    @default_notebook = Notebook.new(tutorial)
    if @default_notebook.save
      notebook_id = @default_notebook.id
      current_user.update_attributes(:active_notebook => notebook_id)
      make_default_notes(notebook_id)
    end
  end

  def make_default_notes(notebook_id)
    note1 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"What is Notable?", "rank"=>1, "depth"=>0, "collapsed"=>false, "parent_id"=>"root" }
    note2 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Notable's mission is to help students \"Learn Faster and Understand More\" by allowing you to quickly take notes in lecture, minimizing distractions when studying from notes, and keeping everything organized for later review.", "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note3 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Watch the video to get started: <span class='tutorial'>Introduction Video</span>", "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note4 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"How does Notable work?", "rank"=>2, "depth"=>0, "collapsed"=>false, "parent_id"=>"root" }
    note5 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<i>Fast</i> - Professors speak too quickly, so Notable has a number of features to help you keep up.", "rank"=>1, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note6 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Utilize keyboard shortcuts to get everything done without the need for a mouse", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note7 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Record audio to serve as a second source of information", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note8 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Type faster by using auto-completion to write out common words and phrases", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note9 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<i>Focused</i> - Notable highlights the main points and tucks everything else away until you need it.", "rank"=>2, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note10 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Expand a note or zoom into it when you want to focus on just that collection of ideas", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note11 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Underline, bold, star, color or highlight to make the key point jump out", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note12 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Work offline to limit access to unproductive websites and email", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note13 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"<i>Flexible</i> - Notable lets you take notes in the way that make the most sense to you.", "rank"=>3, "depth"=>1, "collapsed"=>true, "parent_id"=>"root" }
    note14 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Organize your notes by date, class, subject, color or anything else your heart desires", "rank"=>1, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note15 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Create structure by easily moving your notes around to wherever they belong", "rank"=>2, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note16 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"View your notes as a simple list, hierarchical outline, visual mindmap, or fixed grid", "rank"=>3, "depth"=>2, "collapsed"=>false, "parent_id"=>"root" }
    note17 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>"Helpful Resources", "rank"=>3, "depth"=>0, "collapsed"=>false, "parent_id"=>"root" }
    note18 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>'Keyboard Shortcuts - <a href="/edit" class="titleLink">http://getnotable.com/edit</a>', "rank"=>1, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note19 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>'Give Feedback - <a href="/contact" class="titleLink">http://getnotable.com/contact</a>', "rank"=>2, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }
    note20 = { "guid"=> SecureRandom.uuid, "subtitle"=>"", "fresh"=>true, "notebook_id"=>notebook_id,
      "title"=>'Help Page - <a href="/help" class="titleLink">http://getnotable.com/help</a>', "rank"=>3, "depth"=>1, "collapsed"=>false, "parent_id"=>"root" }

    @default1 = Note.new(note1)
    @default1.save

    note2["parent_id"] = @default1.guid
    @default2 = Note.new(note2)
    @default2.save

    note3["parent_id"] = @default1.guid
    @default3 = Note.new(note3)
    @default3.save

    @default4 = Note.new(note4)
    @default4.save

    note5["parent_id"] = @default4.guid
    @default5 = Note.new(note5)
    @default5.save

    note6["parent_id"] = @default5.guid
    @default6 = Note.new(note6)
    @default6.save

    note7["parent_id"] = @default5.guid
    @default7 = Note.new(note7)
    @default7.save

    note8["parent_id"] = @default5.guid
    @default8 = Note.new(note8)
    @default8.save

    note9["parent_id"] = @default4.guid
    @default9 = Note.new(note9)
    @default9.save

    note10["parent_id"] = @default9.guid
    @default10 = Note.new(note10)
    @default10.save

    note11["parent_id"] = @default9.guid
    @default11 = Note.new(note11)
    @default11.save

    note12["parent_id"] = @default9.guid
    @default12 = Note.new(note12)
    @default12.save

    note13["parent_id"] = @default4.guid
    @default13 = Note.new(note13)
    @default13.save

    note14["parent_id"] = @default13.guid
    @default14 = Note.new(note14)
    @default14.save

    note15["parent_id"] = @default13.guid
    @default15 = Note.new(note15)
    @default15.save

    note16["parent_id"] = @default13.guid
    @default16 = Note.new(note16)
    @default16.save

    @default17 = Note.new(note17)
    @default17.save

    note18["parent_id"] = @default17.guid
    @default18 = Note.new(note18)
    @default18.save

    note19["parent_id"] = @default17.guid
    @default19 = Note.new(note19)
    @default19.save

    note20["parent_id"] = @default17.guid
    @default20 = Note.new(note20)
    @default20.save
  end

end
