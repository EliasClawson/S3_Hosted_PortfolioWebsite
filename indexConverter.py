import markdown

# 1. Grab your content
with open('index.markdown', 'r', encoding='utf-8') as f:
    content = f.read()
    text_html = markdown.markdown(content)

# 2. The Template (Now in Dark Mode)
template = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Elias's Portfolio</title>
    <style>
      /* Main Page Layout - Dark Mode */
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #121212;
        color: #e0e0e0;
        margin: 0;
        padding: 0;
      }
      .wrapper {
        max-width: 800px;
        margin: 40px auto;
        padding: 30px;
        background-color: #1e1e1e;
        border-radius: 8px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.5);
      }
      h1, h2, h3 {
        color: #ffffff;
      }
      a {
        color: #66b3ff;
        text-decoration: none;
      }
      a:hover {
        text-decoration: underline;
      }
      hr {
        border: 0;
        height: 1px;
        background: #333;
        margin: 40px 0;
      }
      
      /* Make sure SVG icons (GitHub/LinkedIn) stay visible */
      svg {
        color: #e0e0e0;
      }
      
      .image-container {
        width: 100%;
        padding-top: 56.25%; /* 16:9 Aspect Ratio */
        position: relative;
        background-color: #252526; /* Matches your dark theme */
        border-radius: 4px;
        overflow: hidden;
        margin-bottom: 15px;
      }

      /* Project Scroller CSS - Dark Mode */
      .project-card {
        display: none; 
        padding: 20px;
        text-align: center;
        background: #2a2a2a;
        border: 1px solid #444;
        border-radius: 12px;
        min-height: 300px;
      }
      .project-card img {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        object-fit: cover; /* This crops the image to fill the frame perfectly */
      }
      .fade {
        animation: fadeAnim 1.5s;
      }
      @keyframes fadeAnim {
        from {opacity: .4} to {opacity: 1}
      }
      .button {
        display: inline-block;
        padding: 10px 20px;
        background-color: #4a90e2;
        color: #fff;
        border-radius: 5px;
        margin-top: 15px;
        font-weight: bold;
      }
      .button:hover {
        background-color: #357abd;
        text-decoration: none;
        color: #fff;
      }
    </style>
</head>
<body>
    <div class="wrapper">
        CONTENT_PLACEHOLDER

        <hr>
        <h2>Featured Projects</h2>
        <div id="project-scroller">Loading projects...</div>
    </div>

    <script>
      let projectIndex = 0;

      function showProjects() {
        let cards = document.getElementsByClassName("project-card");
        if (cards.length === 0) return; 
        
        for (let i = 0; i < cards.length; i++) {
          cards[i].style.display = "none";  
        }
        projectIndex++;
        if (projectIndex > cards.length) {projectIndex = 1}    
        cards[projectIndex-1].style.display = "block";  
        setTimeout(showProjects, 6000); 
      }
        
      async function loadProjects() {
        try {
            const response = await fetch('URL_PLACEHOLDER');
            const projects = await response.json();
            const container = document.getElementById('project-scroller');
            
            if (projects.length === 0) {
                container.innerHTML = "<p>No projects found.</p>";
                return;
            }

            container.innerHTML = projects.map(p => `<div class="project-card fade">
                <div class="image-container">
                    <img src="${p.ImageURL || 'https://via.placeholder.com/800x400/2a2a2a/e0e0e0?text=No+Image+Available'}" alt="${p.Title}">
                </div>
                <h3>${p.Title}</h3>
                <p>${p.Description}</p>
                <a href="${p.Link}" class="button" target="_blank">View on GitHub</a>
              </div>
            `).join('');
            
            showProjects();
        } catch (error) {
            console.error("Failed to load projects:", error);
            document.getElementById('project-scroller').innerHTML = "<p>Error loading projects.</p>";
        }
      }
      
      loadProjects();
    </script>
</body>
</html>
"""

# 3. Swap the placeholders for the real data
api_url = "https://vqjoh7uzdv4p7pw4hlubjyph4y0hjpzs.lambda-url.us-east-1.on.aws/"
full_html = template.replace("CONTENT_PLACEHOLDER", text_html).replace("URL_PLACEHOLDER", api_url)

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(full_html)