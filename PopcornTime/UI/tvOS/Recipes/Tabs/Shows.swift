

import TVMLKitchen
import PopcornKit

class Shows: TabItem, MediaRecipeDelegate  {
    
    let title = "Shows"
    var recipe: ShowsRecipe!
    
    var index: Int {
        return ActionHandler.shared.tabBar.items.index(where: {$0.title == self.title})!
    }
    
    func handler() {
        recipe = recipe ?? {
            let recipe = ShowsRecipe()
            let group = DispatchGroup()
            recipe.delegate = self
            group.enter()
            recipe.loadNextPage { _ in
                group.leave()
            }
            var onDeck: [Episode] = []

            for id in WatchedlistManager<Episode>.episode.getOnDeck() {
                group.enter()
                PopcornKit.getEpisodeInfo(Int(id)!) { (episode, _) in
                    defer { group.leave() }
                    guard let episode = episode else { return }
                    
                    let otherEpisodes                = onDeck.filter({$0.show == episode.show})
                    let earlierEpisodesOutsideSeason = otherEpisodes.filter({$0.season < episode.season})
                    let earlierEpisodesInSeason      = otherEpisodes.filter({$0.season == episode.season}).filter({$0.episode < episode.episode})
                    
                    let earlierEpisodes              = earlierEpisodesOutsideSeason + earlierEpisodesInSeason
                    let laterEpisodes                = otherEpisodes.removing(elements: earlierEpisodes)
                    
                    onDeck = onDeck.removing(elements: earlierEpisodes)
                    
                    laterEpisodes.isEmpty ? onDeck.append(episode) : () // Only append if it is the latest episode in the array
                    
                }
            }
            
            group.notify(queue: .main) {
                self.recipe.onDeck = onDeck
                
                let file = Bundle.main.url(forResource: "MediaRecipe", withExtension: "js")!
                var script = try! String(contentsOf: file)
                script = script.replacingOccurrences(of: "{{RECIPE}}", with: self.recipe.xmlString)
                script = script.replacingOccurrences(of: "{{RECIPE_NAME}}", with: self.recipe.title.lowercased())
                
                ActionHandler.shared.evaluate(script: script)
            }
            return recipe
        }()
        
        ActionHandler.shared.mediaRecipe = recipe
    }
    
    func load(page: Int, filter: String, genre: String, completion: @escaping (String?, NSError?) -> Void) {
        guard let filter = ShowManager.Filters(rawValue: filter), let genre = ShowManager.Genres(rawValue: genre) else { return }
        
        PopcornKit.loadShows(page, filterBy: filter, genre: genre) { (shows, error) in
            completion(shows?.map({$0.lockUp}).joined(separator: ""), error)
        }
    }
}
