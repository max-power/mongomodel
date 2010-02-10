require 'spec_helper'

module MongoModel
  specs_for(Document) do
    describe "has_many association" do
      define_class(:Book, Document) do
        has_many :chapters
      end
      
      it "should default to :by => :foreign_key" do
        Book.associations[:chapters].should be_a(Associations::HasManyByForeignKey)
      end
    end
    
    describe "has_many :by => :foreign_key association" do
      define_class(:Chapter, Document) do
        belongs_to :book
      end
      define_class(:IllustratedChapter, :Chapter)
      define_class(:Book, Document) do
        has_many :chapters, :by => :foreign_key
      end
      define_class(:NonChapter, Document)
      
      let(:chapter1) { Chapter.create!(:id => '1') }
      let(:chapter2) { IllustratedChapter.create!(:id => '2') }
      let(:chapter3) { Chapter.create!(:id => '3') }
      let(:nonchapter) { NonChapter.create! }
      
      context "when uninitialized" do
        subject { Book.new }
        
        it "should be empty" do
          subject.chapters.should be_empty
        end
      end
      
      shared_examples_for "accessing and manipulating a has_many :by => :foreign_key association" do
        it "should access chapters" do
          subject.chapters.should include(chapter1, chapter2)
        end
        
        it "should access chapter ids through association" do
          subject.chapters.ids.should include(chapter1.id, chapter2.id)
        end
        
        it "should add chapters with <<" do
          subject.chapters << chapter3
          subject.chapters.should include(chapter1, chapter2, chapter3)
          chapter3.book.should == subject
        end
        
        it "should add/change chapters with []=" do
          subject.chapters[2] = chapter3
          subject.chapters.should include(chapter1, chapter2, chapter3)
          chapter3.book.should == subject
        end
        
        it "should add chapters with concat" do
          subject.chapters.concat([chapter3])
          subject.chapters.should include(chapter1, chapter2, chapter3)
          chapter3.book.should == subject
        end
        
        it "should insert chapters" do
          subject.chapters.insert(1, chapter3)
          subject.chapters.should include(chapter1, chapter2, chapter3)
          chapter3.book.should == subject
        end
        
        # it "should replace chapters" do
        #   subject.chapters.replace([chapter2, chapter3])
        #   subject.chapters.should == [chapter2, chapter3]
        #   subject.chapter_ids.should == [chapter2.id, chapter3.id]
        # end
        
        it "should add chapters with push" do
          subject.chapters.push(chapter3)
          subject.chapters.should include(chapter1, chapter2, chapter3)
          chapter3.book.should == subject
        end
        
        it "should add chapters with unshift" do
          subject.chapters.unshift(chapter3)
          subject.chapters.should include(chapter3, chapter1, chapter2)
          chapter3.book.should == subject
        end
        
        # it "should clear chapters" do
        #   subject.chapters.clear
        #   subject.chapters.should be_empty
        #   subject.chapter_ids.should be_empty
        # end
        # 
        # it "should remove chapters with delete" do
        #   subject.chapters.delete(chapter1)
        #   subject.chapters.should == [chapter2]
        #   subject.chapter_ids.should == [chapter2.id]
        # end
        # 
        # it "should remove chapters with delete_at" do
        #   subject.chapters.delete_at(0)
        #   subject.chapters.should == [chapter2]
        #   subject.chapter_ids.should == [chapter2.id]
        # end
        # 
        # it "should remove chapters with delete_if" do
        #   subject.chapters.delete_if { |c| c.id == chapter1.id }
        #   subject.chapters.should == [chapter2]
        #   subject.chapter_ids.should == [chapter2.id]
        # end
        
        it "should build a chapter" do
          chapter4 = subject.chapters.build(:id => '4')
          subject.chapters.should include(chapter1, chapter2, chapter4)
          
          chapter4.should be_a_new_record
          chapter4.id.should == '4'
          chapter4.book.should == subject
          chapter4.book_id.should == subject.id
        end
        
        it "should create a chapter" do
          chapter4 = subject.chapters.create(:id => '4')
          subject.chapters.should == [chapter1, chapter2, chapter4]
          
          chapter4.should_not be_a_new_record
          chapter4.id.should == '4'
          chapter4.book.should == subject
          chapter4.book_id.should == subject.id
        end
        
        it "should find chapters" do
          # Create bogus chapters
          Chapter.create!(:id => '999')
          Chapter.create!(:id => '998')
          
          result = subject.chapters.find(:all, :order => :id.desc)
          result.should == [chapter2, chapter1]
        end
      end
      
      context "with chapters set" do
        subject { Book.new(:chapters => [chapter1, chapter2]) }
        it_should_behave_like "accessing and manipulating a has_many :by => :foreign_key association"
      end
      
      context "when loaded from database" do
        let(:book) { Book.create!(:chapters => [chapter1, chapter2]) }
        subject { Book.find(book.id) }
        it_should_behave_like "accessing and manipulating a has_many :by => :foreign_key association"
      end
    end
  end
  
  specs_for(EmbeddedDocument) do
    describe "defining a has_many :by => :foreign_key association" do
      define_class(:Book, EmbeddedDocument)
      
      it "should raise an exception" do
        lambda { Book.has_many :chapters, :by => :foreign_key }.should raise_error
      end
    end
  end
end