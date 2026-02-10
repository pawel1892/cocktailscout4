import { defineAsyncComponent } from 'vue'

/**
 * The Component Registry
 * Keys are the HTML tags (e.g., <test-component>)
 * Values are the dynamic imports.
 */
const components = {
  TestComponent: () => import('../components/Test.vue'),
  AuthForm: () => import('../components/AuthForm.vue'),
  UserSession: () => import('../components/UserSession.vue'),
  RatingControl: () => import('../components/RatingControl.vue'),
  GalleryViewer: () => import('../components/GalleryViewer.vue'),
  RecipeImageGallery: () => import('../components/RecipeImageGallery.vue'),
  CommentForm: () => import('../components/CommentForm.vue'),
  BbcodeEditor: () => import('../components/BbcodeEditor.vue'),
  IngredientCollections: () => import('../components/IngredientCollections.vue'),
  ManageCollectionIngredients: () => import('../components/ManageCollectionIngredients.vue'),
  UserProfileModal: () => import('../components/UserProfileModal.vue'),
  FavoriteToggle: () => import('../components/FavoriteToggle.vue'),
  ContentReportModal: () => import('../components/ContentReportModal.vue'),
  RecipeScaling: () => import('../components/RecipeScaling.vue'),
  RecipeForm: () => import('../components/RecipeForm.vue'),
  IngredientAutocomplete: () => import('../components/IngredientAutocomplete.vue'),
  MarkdownEditor: () => import('../components/MarkdownEditor.vue'),
  // Add future components here:
  // CocktailCard: () => import('../components/CocktailCard.vue'),
}

export default {
  install(app) {
    Object.entries(components).forEach(([name, loadComponent]) => {
      // defineAsyncComponent handles the lazy loading automatically
      app.component(name, defineAsyncComponent(loadComponent))
    })
    
    console.log(`Registered ${Object.keys(components).length} components.`)
  }
}