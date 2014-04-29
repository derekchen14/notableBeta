class Note < ActiveRecord::Base
  require 'securerandom'
  attr_accessible :guid, :eng, :title, :subtitle, :parent_id, :rank, :depth,
    :collapsed, :fresh, :trashed, :notebook_id, :usn
  validates_presence_of :guid, :rank, :depth
  # has_one :leaf, dependent: :destroy
  belongs_to :notebook

  include PgSearch
  pg_search_scope :pg_search, against: [:title, :subtitle],
    using: {tsearch: { dictionary: "english" }},
    associated_against: {notebook: :title} #,
    # ignoring: :accents

  def self.search(query)
    if query.present?
      pg_search(query)
    else
      scoped.order('created_at DESC')
    end
  end

  def self.compileRoot (notebook)
    freshRoots = []
    root_criteria = "parent_id ='root' AND notebook_id=#{notebook.id}"
    roots = Note.where(root_criteria).order(:rank)

    roots.each do |root|
      descendants = Note.getAllDescendants root
      if self.freshBranches?(descendants) or root.fresh
        freshRoots.push(:root => root, :list => descendants)
      end
    end
    freshRoots = add_markup_to(freshRoots, notebook)
  end

  def self.add_markup_to(freshRoots, notebook)
    compiledRoots = []
    freshRoots.each do |r|
      content = generate_content(r)
      compiledRoots.push(
        :title => r[:root].title,
        :content => content,
        :guid => r[:root].eng,
        :id => r[:root].id,
        :created_at => r[:root].created_at,
        :notebook_id => notebook.id,
        :notebook_eng => notebook.eng, #Will be nil on first sync since the eng
        :eng => r[:root].eng           #   is still unknown at that time
      )
    end
    compiledRoots # this is equivalent to one note in Evernote
  end

  def self.generate_content(root)
    currentDepth = 1
    content = "<ul>"
    root[:list].each do |branch|
      if branch.depth == currentDepth and not content.index('<li>').nil?
        content += '</li>'
      end
      content += '<ul>' if branch.depth > currentDepth and currentDepth+=1
      if branch.depth < currentDepth
        content += '</li>'
        currentDepth.downto(branch.depth+1).each do |level|
          content += '</ul></li>'
        end
        currentDepth = branch.depth
      end
      content += "<li>#{branch.title}"
    end
    content += "</li>" if not content.index('<li>').nil?
    currentDepth.downto(2).each do |level|
      content += "</ul></li>"
    end
    content += "</ul>"
  end

  def self.getAllDescendants (root)
    descendantsList = []
    rec = -> (current) do
      descendantsList.push current if current.parent_id != 'root'
      descendants = Note.getPartialDescendants current
      descendants.each do |d|
        rec.call d
      end
    end
    rec.call root
    descendantsList
  end

  def self.getPartialDescendants (branch)
    Note.where("parent_id = '#{branch.guid}'").order(:rank)
  end

  def self.deleteByEng (eng)
    Note.deleteBranch Note.find_by_eng(eng)
  end

  def self.deleteBranch (branch)
    return false if branch.nil?
    self.decreaseRankOfFollowing branch.rank
    self.deleteDescendants branch
    Note.find(branch[:id]).destroy
  end

  def self.deleteDescendants (branch)
    descendantList = Note.getAllDescendants branch
    descendantList.each do |branch|
      Note.find(branch[:id]).destroy
    end
  end

  def self.decreaseRankOfFollowing (rank)
    notes = Note.where("depth = 0")
    notes.each do |n|
      if n.rank > rank
        Note.update(n.id, :rank => n.rank - 1)
      end
    end
  end

  def self.getPossibleConflicts(trunks)
    candidates = []
    trunks.each do |trunk|
      notebook = Notebook.find_by_eng(trunk)
      # find candidates that have been updated since the last sync with Evernote
      candidates.concat Note.where(notebook_id: notebook.id, fresh: true)
    end
    # keep candidates if they have that have never been synced, also limits to only roots
    candidates.delete_if { |note| note.eng.nil?}
    # keep candidates that were created by Notable rather than Evernote
    candidates.delete_if { |note| note.guid == note.eng }
    # the remaining notebooks are candidates for possible conflicts
    candidates
  end

  def self.updateBranch (noteGuid, data)
    nb = Notebook.find_by_guid(data[:nbguid])
    branch = Note.find_by_eng(noteGuid)
    self.deleteDescendants branch
    Note.update(branch.id,
      :title => data[:title],
      :notebook_id => nb.id,
      :usn => data[:usn]
    )
    self.createDescendants branch.guid, data[:content], nb.id
  end

  def self.createBranch (noteGuid, data)
    nb = Notebook.find_by_guid(data[:nbguid])
    rank = self.next_available_rank data[:nbguid]
    noteSettings = {
      :parent_id => 'root',
      :title => data[:title],
      :guid => noteGuid,
      :eng => noteGuid,
      :notebook_id => nb.id,
      :rank => rank,
      :depth => 0,
      :fresh => false,
      :collapsed => false,
      :usn => data[:usn]
    }
    branch = Note.create(noteSettings)
    self.createDescendants noteGuid, data[:content], nb.id
  end

  def self.createDescendants (parent_id, noteContent, notebookId)
    descendants = self.parseContent parent_id, noteContent, notebookId
    descendants.each { |note| Note.create note }
  end

  def self.parseContent (parent_id, content, notebook_id)
    puts "Content before parsing: #{content}"
    content = self.trimContent content
    puts "Content after parsing: #{content}"
    puts "-------------------------"
    notes = []
    indentation = 0
    rec = -> (content) do
      # idea : this part can be refactored,
      # last 'else if' and 'else' would be superfluous
      return notes if content.index('<li>').nil?
      if not (test = content.index('<ul>')).nil? and test.zero?
        indentation +=1
        rec.call content.slice content.index('<li>'), content.size
      elsif not (test = content.index('</ul>')).nil? and test.zero?
        indentation -=1
        rec.call content.slice '</ul>'.size, content.size
      elsif not (test = content.index('<li>')).nil? and test.zero?
        hash = self.getContentNextLi content
        title = hash[:title]
        index = hash[:index]
        notes.push :depth => indentation, :title => title, :guid => SecureRandom.uuid
        rec.call(content.slice index, content.size)
      else
        notes
      end
    end
    rec.call content

    preceding = {:depth => 0, :title => "empty note", :guid => parent_id}
    parents = [{:guid => parent_id, :next_rank => 1}]
    notes2 = notes
    notes2.each do |n|
      parent = parents[n[:depth] - 1]
      if n[:depth] > preceding[:depth]
        parents[preceding[:depth]] = {:guid => preceding[:guid], :next_rank => 2}
        n[:rank] = 1
        n[:parent_id] = preceding[:guid]
      elsif n[:depth] < preceding[:depth]
        n[:rank] = parent[:next_rank]
        n[:parent_id] = parent[:guid]
        parent[:next_rank] += 1
      else
        n[:rank] = parent[:next_rank]
        n[:parent_id] = parent[:guid]
        parent[:next_rank] += 1
      end
      n[:notebook_id] = notebook_id
      preceding = n
    end

    notes
  end

  # this obscure code retrieve what is between <en-note>...</en-note> and trims the rest
  def self.retrieveContentFromEnml (content)
    if content.index(/<en-note( .*?)?>/)
      content = content.slice((i1 = content.index($~[0]) + $~[0].size), (content.index('</en-note>') - i1))
    end
    content
  end

  def self.trimContent (content)
    content = self.retrieveContentFromEnml content
    content = self.transformPlainText content # if content.index('<ul>').nil?
    content = content.gsub />(\s)+</, '><' # Delete space between <tags>
    content = content.gsub /<(\/)?(?!ul|li|ol|\/ul|\/ol)(.*?)?(\/)?>/, ''  # strip out any other tags, that are not the allowed li, ul or ol
    # content = content.gsub /<(\/)?(?!ul|li|ol)(.*?)?(\/)?>/, '' # strip out any other not li or ul tags
    content = content.gsub /<li (.*?)style=('|").*?none.*?('|")(.*?)>/, '' # To strip out hidden li added by mce editor in evernote
    content = content.gsub /<ol( .*?)?>/, '<ul>'  # Strip <ol> tag attributes
    content = content.gsub /<\/ol>/, '</ul>'      # Convert </ol> to </ul> tags
    content = content.gsub /<li( .*?)?>/, '<li>'  # Strip out <li> tag attributes
    content = content.gsub /<ul( .*?)?>/, '<ul>'  # Strip our <ul> tag attributes
    content = content.gsub /<\/li>/, '' # Strip out closing li
    if content.match /<ul>(<ul>)+/
      content = content.gsub /<(\/)?ul>/, '' # strip out all uls
      content = '<ul>' + content + '</ul>'
    end
    content
  end

  def self.getContentNextLi (content)
    t = content.slice '<li>'.size, content.index(/<(\/)?(li|ul)>/, 4) - '<li>'.size
    {:title  => t, :index => $~.begin(0)}
  end

  # def self.getContentNextLi (content)
  #   nextTag = content.index(/<(\/)?(li|ul)>/, 4)
  #   nextTag ||= content.size # Meaning there is only a li tag left open, and no closing tag
  #   t = content.slice '<li>'.size, nextTag - '<li>'.size
  #   if not $~.nil?
  #     index = $~.begin(0)
  #   else
  #     index = content.size
  #   end
  #   {:title  => t, :index => index}
  # end

  def self.transformPlainText (content)
    content = content.gsub '<div></div>', ''
    content = content.gsub '<div>', '<li>'
    content = content.gsub '<p>', '<li>'
    content = '<ul>' + content + '</ul>' if content.index('<ul>').nil? or not content.index('<ul>').zero?
    content
  end

  def self.next_available_rank (notebook_guid)
    nb = Notebook.find_by_guid(notebook_guid)
    lastNote = Note.where("notebook_id=#{nb.id}").order("depth, rank DESC").first
    if lastNote.nil? then 1 else lastNote.rank+1 end
  end

  def self.setDefaultAttributes (data)
    defaults = {
      :collapsed => false,
      :fresh => false,
      :guid => data[:eng],
    }
  end

  def self.freshBranches? (descendantList)
    fresh = false
    descendantList.each do |descendant|
      fresh = descendant.fresh
      break if fresh == true
    end
    fresh
  end

  def compileBranches (root)
    data #breakdown into branches
    # with an appropriate rank, depth
    # title, subtitle, parent_id
    collapsed = false
    fresh = false
    guid = @noteGuid
  end

  def markStale
    if branch.isCompiled?
      branch.fresh = false
    end
  end

  def self.getTrashed
    Note.where("trashed = true AND parent_id = 'root'")
  end

end
