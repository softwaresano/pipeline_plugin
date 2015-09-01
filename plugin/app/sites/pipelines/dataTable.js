function DataTable(title, description, sections) {
      var title;
      var description;
      var sections;
      
      this.getTitle = function() {
            return this.title;
      };
    
      this.getDescription = function() {
            return this.description;
      };

      this.getSections = function() {
            return this.sections;
      };

      this.setTitle = function(pTitle) {
            this.title = pTitle;
      };

      this.setDescription = function(pDescription) {
            this.description = pDescription;
      };

      this.setSections = function(pSections) {
            this.sections = pSections;
      }
}

function Section(title, description, head, data, sumarize) {
      var title;
      var description;
      var head;
      var data;
      var sumarize;
      
      this.getTitle = function() {
            return this.title;
      };
    
      this.getDescription = function() {
            return this.description;
      };

      this.getHead = function() {
            return this.head;
      };

      this.getData = function() {
            return this.data;
      };

      this.getSumarize = function() {
            return this.sumarize;
      };

      this.setTitle = function(pTitle) {
            this.title = pTitle;
      };

      this.setDescription = function(pDescription) {
            this.description = pDescription;
      };

      this.setHead = function(pHead) {
            this.head = pHead;
      }
      
      this.setData = function(pData) {
            this.data = pData;
      }
      
      this.setSumarize = function(pSumarize) {
            this.sumarize = pSumarize;
      }
}
