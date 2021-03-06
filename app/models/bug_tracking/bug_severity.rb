=begin rdoc

Bug severity.

=end
class BugSeverity < ActiveRecord::Base
  include Comparable
  # 7 different severities in default bugzilla setting
  Colors_Bugzilla = {
            :blocker     => '#FF0000',
            :critical    => '#FF00FF',
            :major       => '#0000FF',
            :normal      => '#BBCC00',
            :minor       => '#555555',
            :trivial     => '#555500',
            :enhancement => '#00FF00'
           }
  # 5 different severities in default redmine setting
  Colors_Redmine = {
            :immediate  => '#FF0000',
            :urgent     => '#FF00FF',
            :high       => '#0000FF',
            :normal     => '#BBCC00',
            :low        => '#555555'
           }

  # Return color for bug severity/priority depending bug tracker.
  #
  # Use configured color for given tracker type from environment.rb if
  # it's available, otherwise use hardcoded values or default to black
  def self.color(name, tracker_type='bugzilla')
    n = name.gsub(' ', '_').downcase.to_sym
    bt = tracker_type.gsub(' ', '_').downcase.to_sym
    unless BT_CONFIG[bt].blank? or BT_CONFIG[bt][:severities].blank?
      col = BT_CONFIG[bt][:severities][n]
    end
    
    if tracker_type == "bugzilla"
      col ||= Colors_Bugzilla[n] || '#000000'
    elsif tracker_type == "redmine"
      col ||= Colors_Redmine[n] || '#000000'
    else
      col = '#000000'
    end
    col
  end

  has_many :bugs, :dependent => :destroy
  belongs_to :bug_tracker
  validates_presence_of :bug_tracker_id, :name, :external_id
  validates_uniqueness_of :external_id, :scope => :bug_tracker_id

  # default ordering
  scope :ordered, order('sortkey ASC')
  scope :at_least, lambda {|sev, bt_id|
    { :conditions => "sortkey <= (select sortkey from bug_severities "+
                     "where name='#{sev}' and bug_tracker_id=#{bt_id})"}
  }

  def self.external_id_scope; :bug_tracker; end
  def deleted; false; end
  def <=>(other)
    self.sortkey <=> other.sortkey
  end
end
